# frozen_string_literal: true

module DiscourseKuuPoints
  class TasksController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    def summary
      render json: Summary.for(current_user)
    end

    # 签到按钮；「转发」由主题的分享菜单在复制链接、保存 / 复制分享图成功后调用。
    # 今天已经完成过也返回 200，rewarded 是 false
    def complete
      DailyTask::Complete.call(guardian:, params: { task: params[:task] }) do |result|
        on_success do
          render json: {
                   rewarded: result[:entry_id].present?,
                   xp: result[:xp],
                   coins: result[:coins],
                   summary: Summary.for(current_user),
                 }
        end
        on_failed_contract { raise Discourse::NotFound }
        on_failed_policy(:can_earn) do
          render(
            json: failed_json.merge(errors: [I18n.t("kuu_points.errors.cannot_earn")]),
            status: :forbidden,
          )
        end
      end
    end
  end
end
