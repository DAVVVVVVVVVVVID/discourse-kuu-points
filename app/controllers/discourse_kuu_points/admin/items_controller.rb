# frozen_string_literal: true

module DiscourseKuuPoints
  module Admin
    class ItemsController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME

      before_action :ensure_admin

      def index
        render json: { items: AdminItems.as_json }
      end

      def create
        save
      end

      def update
        save
      end

      private

      def save
        Item::Save.call(service_params) do
          on_success { render json: { items: AdminItems.as_json } }
          on_failed_contract do |contract|
            render(
              json: failed_json.merge(errors: contract.errors.full_messages),
              status: :bad_request,
            )
          end
          on_failed_policy(:admin) { raise Discourse::InvalidAccess }
          on_model_not_found(:item) { raise Discourse::NotFound }
          on_model_errors(:item) do |item|
            render(
              json: failed_json.merge(errors: item.errors.full_messages),
              status: :unprocessable_content,
            )
          end
        end
      end
    end
  end
end
