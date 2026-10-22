# frozen_string_literal: true

module DiscourseKuuPoints
  # 测试用的头像框和饰品（图片由 script/make_demo_items.sh 生成）。正式商品由管理员在后台上传，
  # 测试商品可以在后台下架
  module DemoItems
    ITEMS = [
      { name: "樱花圆环", kind: "frame", price: 30, file: "sakura-frame.png" },
      { name: "藏青双环", kind: "frame", price: 50, file: "navy-frame.png" },
      { name: "一朵樱花", kind: "accessory", price: 20, file: "sakura-accessory.png" },
    ].freeze

    # 已经有同名商品的跳过，可以重复执行。返回新建的商品
    def self.create!
      ITEMS.each_with_index.filter_map do |attributes, index|
        next if Item.exists?(name: attributes[:name])

        path = File.join(__dir__, "demo_items", attributes[:file])
        upload =
          UploadCreator.new(File.open(path), attributes[:file]).create_for(
            Discourse::SYSTEM_USER_ID,
          )
        raise upload.errors.full_messages.to_sentence if upload.errors.present?

        Item.create!(attributes.except(:file).merge(upload:, position: index))
      end
    end
  end
end
