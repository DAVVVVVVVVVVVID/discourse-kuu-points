# frozen_string_literal: true

module DiscourseKuuPoints
  # 后台商品列表：全部商品（包括下架的），带拥有人数
  module AdminItems
    def self.as_json
      owners = UserItem.group(:item_id).count
      Item
        .includes(:upload)
        .ordered
        .map do |item|
          {
            id: item.id,
            name: item.name,
            kind: item.kind,
            price: item.price,
            enabled: item.enabled,
            position: item.position,
            upload_id: item.upload_id,
            image_url: item.image_url,
            owners_count: owners[item.id] || 0,
          }
        end
    end
  end
end
