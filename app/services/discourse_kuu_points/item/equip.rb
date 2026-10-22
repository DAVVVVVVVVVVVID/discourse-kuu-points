# frozen_string_literal: true

module DiscourseKuuPoints
  # 佩戴自己拥有的头像框或饰品，换掉同一类里原来戴的那个（同时最多一个头像框 + 一个饰品）
  class Item::Equip
    include Service::Base

    params do
      attribute :item_id, :integer

      validates :item_id, presence: true
    end

    model :item
    policy :owned
    step :equip

    private

    def fetch_item(params:)
      Item.find_by(id: params.item_id)
    end

    def owned(guardian:, item:)
      UserItem.exists?(user_id: guardian.user.id, item_id: item.id)
    end

    def equip(guardian:, item:)
      Account.ensure_exists!(guardian.user.id)
      Account.where(user_id: guardian.user.id).update_all(item.slot => item.id)
    end
  end
end
