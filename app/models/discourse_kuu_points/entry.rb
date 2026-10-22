# frozen_string_literal: true

module DiscourseKuuPoints
  # 经验 / 鲸币明细，一行一笔。每日任务的 reason 是任务名（DailyTask::TASKS），带 task_date
  class Entry < ActiveRecord::Base
    self.table_name = "kuu_points_entries"

    belongs_to :user
    belongs_to :post, optional: true
    belongs_to :acting_user, class_name: "User", optional: true
    belongs_to :item, optional: true

    # 记一笔每日任务。这个任务今天已经记过（包括并发的另一个请求刚记上）时返回 nil
    def self.record_task(user_id:, task:, task_date:, xp:, coins:, post_id: nil)
      DB.query_single(
        <<~SQL,
        INSERT INTO kuu_points_entries (user_id, reason, xp, coins, task_date, post_id, created_at)
        VALUES (:user_id, :task, :xp, :coins, :task_date, :post_id, :now)
        ON CONFLICT (user_id, reason, task_date) WHERE task_date IS NOT NULL DO NOTHING
        RETURNING id
      SQL
        user_id:,
        task:,
        task_date:,
        xp:,
        coins:,
        post_id:,
        now: Time.zone.now,
      ).first
    end
  end
end

# == Schema Information
#
# Table name: kuu_points_entries
#
#  id             :bigint           not null, primary key
#  coins          :integer          default(0), not null
#  note           :string(500)
#  reason         :string           not null
#  task_date      :date
#  xp             :integer          default(0), not null
#  created_at     :datetime         not null
#  acting_user_id :integer
#  item_id        :bigint
#  post_id        :integer
#  user_id        :integer          not null
#
# Indexes
#
#  index_kuu_points_entries_on_user_id_and_created_at  (user_id,created_at)
#  index_kuu_points_entries_once_per_day               (user_id,reason,task_date) UNIQUE WHERE (task_date IS NOT NULL)
#
