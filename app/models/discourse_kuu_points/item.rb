# frozen_string_literal: true

module DiscourseKuuPoints
  # 鲸币商城的商品。kind 是 frame（头像框）或 accessory（饰品），两种都是叠在头像上的方形透明 PNG
  class Item < ActiveRecord::Base
    self.table_name = "kuu_points_items"

    KINDS = %w[frame accessory].freeze

    belongs_to :upload
    # 登记引用，core 定期清理没人引用的上传时不会删掉商品图片
    has_many :upload_references, as: :target, dependent: :destroy

    scope :enabled, -> { where(enabled: true) }
    scope :ordered, -> { order(:position, :id) }

    validates :name, presence: true, length: { maximum: 50 }
    validates :upload, presence: true
    validates :kind, inclusion: { in: KINDS }
    validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    after_save do
      if saved_change_to_upload_id?
        UploadReference.ensure_exist!(upload_ids: [upload_id], target: self)
      end
    end

    def image_url
      Discourse.store.cdn_url(upload.url) if upload
    end

    # 账户上记佩戴的列：frame_item_id / accessory_item_id
    def slot
      :"#{kind}_item_id"
    end
  end
end

# == Schema Information
#
# Table name: kuu_points_items
#
#  id         :bigint           not null, primary key
#  enabled    :boolean          default(TRUE), not null
#  kind       :string           not null
#  name       :string(50)       not null
#  position   :integer          default(0), not null
#  price      :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  upload_id  :integer          not null
#
