# frozen_string_literal: true

# name: discourse-kuu-points
# about: 经验值和等级、鲸币、每日任务、鲸币商城和头像装饰
# version: 0.0.1
# authors: DAVVVVVVVVVVVID
# url: https://github.com/DAVVVVVVVVVVVID/discourse-kuu-points
# required_version: 2026.1.0

enabled_site_setting :kuu_points_enabled

register_asset "stylesheets/common/kuu-points.scss"

add_admin_route "kuu_points.admin.title", "discourse-kuu-points", use_new_show_route: true

register_svg_icon "coins"
register_svg_icon "circle-check"
register_svg_icon "far-circle"

module ::DiscourseKuuPoints
  PLUGIN_NAME = "discourse-kuu-points"

  TIME_ZONE = "Asia/Tokyo"

  # 每日任务按日本时间 0 点分界
  def self.today
    Time.zone.now.in_time_zone(TIME_ZONE).to_date
  end

  # 被封禁、禁言的用户和系统账号不发奖励。运营号、鲸仔照常参与（Issue #1）
  def self.can_earn?(user)
    return false if user.nil? || user.staged? || user.id == Discourse::SYSTEM_USER_ID

    !user.suspended? && !user.silenced?
  end
end

require_relative "lib/discourse_kuu_points/engine"

after_initialize do
  on(:post_created) do |post, _opts, _user|
    DiscourseKuuPoints::DailyTask.post_created(post) if SiteSetting.kuu_points_enabled
  end

  on(:like_created) do |post_action, _creator|
    DiscourseKuuPoints::DailyTask.like_created(post_action) if SiteSetting.kuu_points_enabled
  end

  # 帖子里头像上的装饰和用户名旁的等级。帖子页一次查出所有发帖人，避免每条帖子查一次
  add_to_class(:topic_view, :kuu_points_decorations) do
    @kuu_points_decorations ||= DiscourseKuuPoints::Decoration.for_users(posts.map(&:user_id).uniq)
  end

  add_to_serializer(:post, :kuu_points, include_condition: -> { object.user_id.present? }) do
    if @topic_view
      @topic_view.kuu_points_decorations[object.user_id] || DiscourseKuuPoints::Decoration::DEFAULT
    else
      DiscourseKuuPoints::Decoration.for_user(object.user_id)
    end
  end

  # 用户卡片和个人主页（UserSerializer 继承 UserCardSerializer）
  add_to_serializer(:user_card, :kuu_points) { DiscourseKuuPoints::Decoration.for_user(object.id) }
end
