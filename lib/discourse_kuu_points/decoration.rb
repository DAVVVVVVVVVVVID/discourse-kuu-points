# frozen_string_literal: true

module DiscourseKuuPoints
  # 帖子、用户卡片、个人主页上显示的等级和正在佩戴的头像框 / 饰品。没有账户的用户是 1 级、没有装饰
  module Decoration
    DEFAULT = { level: 1, frame_url: nil, accessory_url: nil }.freeze

    def self.for_users(user_ids)
      Account
        .where(user_id: user_ids)
        .includes(frame_item: :upload, accessory_item: :upload)
        .to_h do |account|
          [
            account.user_id,
            {
              level: account.level,
              frame_url: account.frame_item&.image_url,
              accessory_url: account.accessory_item&.image_url,
            },
          ]
        end
    end

    def self.for_user(user_id)
      for_users([user_id])[user_id] || DEFAULT
    end
  end
end
