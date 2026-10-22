# frozen_string_literal: true

module DiscourseKuuPoints
  # 完成一项每日任务：同一任务每人每个日本日只发一次奖励。今天已经领过时照样成功，rewarded 是 false
  class DailyTask::Complete
    include Service::Base

    params do
      attribute :task, :string
      attribute :post_id, :integer

      validates :task, inclusion: { in: DailyTask::TASKS }
    end

    policy :can_earn

    transaction do
      step :record_entry
      only_if(:rewarded) { step :credit_account }
    end

    private

    def can_earn(guardian:)
      DiscourseKuuPoints.can_earn?(guardian.user)
    end

    def record_entry(guardian:, params:)
      context[:xp], context[:coins] = DailyTask.reward(params.task)
      context[:entry_id] = Entry.record_task(
        user_id: guardian.user.id,
        task: params.task,
        task_date: DiscourseKuuPoints.today,
        xp: context[:xp],
        coins: context[:coins],
        post_id: params.post_id,
      )
    end

    def rewarded(entry_id:)
      entry_id.present?
    end

    def credit_account(guardian:, xp:, coins:)
      Account.credit!(user_id: guardian.user.id, xp:, coins:)
    end
  end
end
