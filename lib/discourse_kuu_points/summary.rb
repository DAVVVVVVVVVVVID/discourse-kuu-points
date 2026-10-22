# frozen_string_literal: true

module DiscourseKuuPoints
  # 用户自己的等级、经验进度、鲸币余额和今日任务，鲸币商城顶部用
  module Summary
    def self.for(user)
      account = Account.find_by(user_id: user.id) || Account.new(user_id: user.id)
      done = DailyTask.completed_today(user)

      {
        level: account.level,
        max_level: Level::MAX,
        xp: account.xp,
        level_xp: Level.level_xp(account.level),
        next_level_xp: Level.next_level_xp(account.xp),
        coins: account.coins,
        tasks:
          DailyTask::TASKS.map do |task|
            xp, coins = DailyTask.reward(task)
            { task:, done: done.include?(task), xp:, coins: }
          end,
      }
    end
  end
end
