# frozen_string_literal: true

class CreateKuuPointsItems < ActiveRecord::Migration[8.1]
  def change
    # 鲸币商城的商品：头像框（frame）或饰品（accessory），图片是方形透明 PNG，叠在头像上
    create_table :kuu_points_items do |t|
      t.string :name, null: false, limit: 50
      t.string :kind, null: false
      t.integer :upload_id, null: false
      t.integer :price, null: false
      t.boolean :enabled, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_check_constraint :kuu_points_items,
                         "kind IN ('frame', 'accessory')",
                         name: "kuu_points_items_kind"
    add_check_constraint :kuu_points_items, "price >= 0", name: "kuu_points_items_price"

    # 兑换后永久拥有；下架的商品已拥有的人照样能戴
    create_table :kuu_points_user_items do |t|
      t.integer :user_id, null: false
      t.bigint :item_id, null: false
      t.datetime :created_at, null: false
    end

    add_index :kuu_points_user_items, %i[user_id item_id], unique: true

    # 同时最多戴一个头像框 + 一个饰品
    add_column :kuu_points_accounts, :frame_item_id, :bigint
    add_column :kuu_points_accounts, :accessory_item_id, :bigint

    # 兑换的明细记下是哪件商品
    add_column :kuu_points_entries, :item_id, :bigint
  end
end
