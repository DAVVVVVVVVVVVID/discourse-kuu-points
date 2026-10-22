# frozen_string_literal: true

module DiscourseKuuPoints
  # 鲸币商城页的内容：顶部概况、在售商品和自己已拥有的商品（下架了的也在，「我的装饰」里照样能戴）
  module Shop
    def self.for(user)
      account = Account.find_by(user_id: user.id)
      owned_ids = UserItem.where(user_id: user.id).pluck(:item_id)
      equipped_ids = [account&.frame_item_id, account&.accessory_item_id].compact
      items = Item.includes(:upload).where(enabled: true).or(Item.where(id: owned_ids)).ordered

      {
        summary: Summary.for(user),
        items:
          items.map do |item|
            {
              id: item.id,
              name: item.name,
              kind: item.kind,
              price: item.price,
              image_url: item.image_url,
              enabled: item.enabled,
              owned: owned_ids.include?(item.id),
              equipped: equipped_ids.include?(item.id),
            }
          end,
      }
    end
  end
end
