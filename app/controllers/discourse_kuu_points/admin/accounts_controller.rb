# frozen_string_literal: true

module DiscourseKuuPoints
  module Admin
    class AccountsController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME

      before_action :ensure_admin

      RECENT_ENTRIES = 20

      # 调整前先看这个用户现在的经验、鲸币和最近的明细
      def show
        user = User.find_by_username(params[:username])
        raise Discourse::NotFound if user.nil?

        render json: account_json(user)
      end

      def adjust
        Account::Adjust.call(service_params) do |result|
          on_success { render json: account_json(result[:user]) }
          on_failed_contract do |contract|
            render(
              json: failed_json.merge(errors: contract.errors.full_messages),
              status: :bad_request,
            )
          end
          on_failed_policy(:admin) { raise Discourse::InvalidAccess }
          on_model_not_found(:user) { raise Discourse::NotFound }
          on_failed_step(:credit) do
            render(
              json: failed_json.merge(errors: [I18n.t("kuu_points.errors.below_zero")]),
              status: :unprocessable_content,
            )
          end
        end
      end

      private

      def account_json(user)
        entries =
          Entry
            .where(user_id: user.id)
            .includes(:item, :acting_user)
            .order(created_at: :desc, id: :desc)
            .limit(RECENT_ENTRIES)

        {
          user: BasicUserSerializer.new(user, root: false).as_json,
          summary: Summary.for(user),
          entries:
            entries.map do |entry|
              EntrySerializer
                .new(entry, root: false)
                .as_json
                .merge(acting_username: entry.acting_user&.username)
            end,
        }
      end
    end
  end
end
