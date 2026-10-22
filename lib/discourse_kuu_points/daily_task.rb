# frozen_string_literal: true

module DiscourseKuuPoints
  # 五项每日任务（Issue #1 第 2 条）。经验 / 鲸币数值在站点设置里，例如 kuu_points_checkin_xp
  module DailyTask
    TASKS = %w[checkin topic reply like share].freeze

    # 由用户点按钮 / 前端通知完成的任务；发帖、回复、点赞挂在 core 的事件上
    CLIENT_TASKS = %w[checkin share].freeze

    def self.reward(task)
      [SiteSetting.get("kuu_points_#{task}_xp"), SiteSetting.get("kuu_points_#{task}_coins")]
    end

    def self.completed_today(user)
      return [] if user.nil?

      Entry.where(user_id: user.id, task_date: DiscourseKuuPoints.today, reason: TASKS).pluck(
        :reason,
      )
    end

    # 发帖和回复：PostCreator 发出的都算，包括评分、二手插件直接建的帖子和评分短评。
    # 私信、密语和小动作帖子不算
    def self.post_created(post)
      return if post.topic.nil? || post.topic.private_message?
      return if post.post_type != Post.types[:regular]

      complete(post.user, post.is_first_post? ? "topic" : "reply", post_id: post.id)
    end

    # 给别人的帖子点赞；私信里的不算。取消点赞不扣
    def self.like_created(post_action)
      post = post_action.post
      return if post.nil? || post.user_id == post_action.user_id
      return if post.topic.nil? || post.topic.private_message?

      complete(post_action.user, "like", post_id: post.id)
    end

    def self.complete(user, task, post_id: nil)
      return if user.nil?

      Complete.call(guardian: user.guardian, params: { task:, post_id: })
    end
  end
end
