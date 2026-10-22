# frozen_string_literal: true

module DiscourseKuuPoints
  class ItemsController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    def redeem
      Item::Redeem.call(service_params) do
        on_success { render json: Shop.for(current_user) }
        on_failed_contract { raise Discourse::NotFound }
        on_model_not_found(:item) { raise Discourse::NotFound }
        on_failed_policy(:not_owned) { render_error("already_owned") }
        on_failed_step(:grant) { render_error("already_owned") }
        on_failed_step(:pay) { render_error("not_enough_coins") }
      end
    end

    def equip
      Item::Equip.call(service_params) do
        on_success { render json: Shop.for(current_user) }
        on_failed_contract { raise Discourse::NotFound }
        on_model_not_found(:item) { raise Discourse::NotFound }
        on_failed_policy(:owned) { raise Discourse::InvalidAccess }
      end
    end

    def unequip
      Item::Unequip.call(service_params) do
        on_success { render json: Shop.for(current_user) }
        on_failed_contract { raise Discourse::NotFound }
        on_model_not_found(:item) { raise Discourse::NotFound }
      end
    end

    private

    def render_error(key)
      render(
        json: failed_json.merge(errors: [I18n.t("kuu_points.errors.#{key}")]),
        status: :unprocessable_content,
      )
    end
  end
end
