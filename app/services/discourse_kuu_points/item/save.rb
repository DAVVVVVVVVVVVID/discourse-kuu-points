# frozen_string_literal: true

module DiscourseKuuPoints
  # 管理员新增或编辑商品（上下架就是改 enabled）。商品类型建好后不能改：有人正戴着时会对不上
  class Item::Save
    include Service::Base

    params do
      attribute :item_id, :integer
      attribute :name, :string
      attribute :kind, :string
      attribute :upload_id, :integer
      attribute :price, :integer
      attribute :enabled, :boolean, default: true
      attribute :position, :integer, default: 0

      validates :name, presence: true, length: { maximum: 50 }
      validates :upload_id, presence: true
      validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
      validates :kind, inclusion: { in: Item::KINDS }, if: -> { item_id.blank? }
    end

    policy :admin
    model :item
    step :save_item
    step :log_action

    private

    def admin(guardian:)
      guardian.is_admin?
    end

    # 新建时 kind 由参数定，编辑时不改
    def fetch_item(params:)
      item =
        params.item_id.present? ? Item.find_by(id: params.item_id) : Item.new(kind: params.kind)
      item&.tap do
        it.assign_attributes(params.attributes.slice(*%w[name upload_id price enabled position]))
      end
    end

    def save_item(item:)
      context[:created] = item.new_record?
      item.save!
    end

    def log_action(guardian:, item:, created:)
      StaffActionLogger.new(guardian.user).log_custom(
        created ? "kuu_points_item_create" : "kuu_points_item_update",
        {
          item_id: item.id,
          name: item.name,
          kind: item.kind,
          price: item.price,
          enabled: item.enabled,
        },
      )
    end
  end
end
