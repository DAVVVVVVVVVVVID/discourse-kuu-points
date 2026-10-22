# frozen_string_literal: true

module DiscourseKuuPoints
  # 用鲸币兑换商品，永久拥有。余额不够、已经拥有时不扣。并发兑换靠 user_items 的唯一索引和
  # 条件扣款防重复、防扣成负数
  class Item::Redeem
    include Service::Base

    params do
      attribute :item_id, :integer

      validates :item_id, presence: true
    end

    model :item
    policy :not_owned

    transaction do
      step :grant
      step :pay
      step :record_entry
    end

    private

    def fetch_item(params:)
      Item.enabled.find_by(id: params.item_id)
    end

    def not_owned(guardian:, item:)
      !UserItem.exists?(user_id: guardian.user.id, item_id: item.id)
    end

    def grant(guardian:, item:)
      granted = DB.exec(<<~SQL, user_id: guardian.user.id, item_id: item.id, now: Time.zone.now)
        INSERT INTO kuu_points_user_items (user_id, item_id, created_at)
        VALUES (:user_id, :item_id, :now)
        ON CONFLICT (user_id, item_id) DO NOTHING
      SQL
      fail!("already owned") if granted == 0
    end

    def pay(guardian:, item:)
      fail!("not enough coins") if !Account.credit!(user_id: guardian.user.id, coins: -item.price)
    end

    def record_entry(guardian:, item:)
      Entry.create!(user_id: guardian.user.id, reason: "redeem", coins: -item.price, item:)
    end
  end
end
