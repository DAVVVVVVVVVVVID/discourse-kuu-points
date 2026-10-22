# frozen_string_literal: true

module DiscourseKuuPoints
  # 用户当前的经验和鲸币。只通过 credit! 增减，和明细在同一个事务里写
  class Account < ActiveRecord::Base
    self.table_name = "kuu_points_accounts"

    belongs_to :user
    belongs_to :frame_item, class_name: "DiscourseKuuPoints::Item", optional: true
    belongs_to :accessory_item, class_name: "DiscourseKuuPoints::Item", optional: true

    # 加减经验 / 鲸币，没有记录时新建。扣到负数时不改、返回 false（表上也有约束兜底）
    def self.credit!(user_id:, xp: 0, coins: 0)
      ensure_exists!(user_id)
      DB.exec(<<~SQL, user_id:, xp:, coins:, now: Time.zone.now) == 1
        UPDATE kuu_points_accounts
        SET xp = xp + :xp, coins = coins + :coins, updated_at = :now
        WHERE user_id = :user_id AND xp + :xp >= 0 AND coins + :coins >= 0
      SQL
    end

    def self.ensure_exists!(user_id)
      now = Time.zone.now
      DB.exec(<<~SQL, user_id:, now:)
        INSERT INTO kuu_points_accounts (user_id, created_at, updated_at)
        VALUES (:user_id, :now, :now)
        ON CONFLICT (user_id) DO NOTHING
      SQL
    end

    def level
      Level.for(xp)
    end
  end
end

# == Schema Information
#
# Table name: kuu_points_accounts
#
#  id                :bigint           not null, primary key
#  coins             :integer          default(0), not null
#  xp                :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  accessory_item_id :bigint
#  frame_item_id     :bigint
#  user_id           :integer          not null
#
# Indexes
#
#  index_kuu_points_accounts_on_user_id  (user_id) UNIQUE
#
