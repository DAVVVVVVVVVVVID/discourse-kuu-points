# frozen_string_literal: true

class CreateKuuPointsAccountsAndEntries < ActiveRecord::Migration[8.1]
  def change
    # 每人一行：经验和鲸币的当前值，由明细累加而来。没有记录的用户就是 0
    create_table :kuu_points_accounts do |t|
      t.integer :user_id, null: false
      t.integer :xp, null: false, default: 0
      t.integer :coins, null: false, default: 0
      t.timestamps
    end

    add_index :kuu_points_accounts, :user_id, unique: true
    add_check_constraint :kuu_points_accounts, "xp >= 0", name: "kuu_points_accounts_xp"
    add_check_constraint :kuu_points_accounts, "coins >= 0", name: "kuu_points_accounts_coins"

    # 明细：每一笔经验 / 鲸币的增减和来源。每日任务带 task_date（日本时间的日期），
    # 同一任务同一天只能有一条，靠唯一索引防并发重复发放
    create_table :kuu_points_entries do |t|
      t.integer :user_id, null: false
      t.string :reason, null: false
      t.integer :xp, null: false, default: 0
      t.integer :coins, null: false, default: 0
      t.date :task_date
      t.integer :post_id
      t.integer :acting_user_id
      t.string :note, limit: 500
      t.datetime :created_at, null: false
    end

    add_index :kuu_points_entries, %i[user_id created_at]
    add_index :kuu_points_entries,
              %i[user_id reason task_date],
              unique: true,
              where: "task_date IS NOT NULL",
              name: "index_kuu_points_entries_once_per_day"
  end
end
