# frozen_string_literal: true

module DiscourseKuuPoints
  # 取下正在戴的头像框或饰品
  class Item::Unequip
    include Service::Base

    params do
      attribute :item_id, :integer

      validates :item_id, presence: true
    end

    model :item
    step :unequip

    private

    def fetch_item(params:)
      Item.find_by(id: params.item_id)
    end

    def unequip(guardian:, item:)
      Account.where(:user_id => guardian.user.id, item.slot => item.id).update_all(item.slot => nil)
    end
  end
end
