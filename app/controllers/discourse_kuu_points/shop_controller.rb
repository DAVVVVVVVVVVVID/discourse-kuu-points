# frozen_string_literal: true

module DiscourseKuuPoints
  class ShopController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    # 鲸币商城页直接打开时由 check_xhr 交给前端，未登录也要能打开页面看到登录提示
    requires_login except: %i[show]

    ENTRIES_PER_PAGE = 20

    def show
      raise Discourse::NotLoggedIn if current_user.nil?

      render json: Shop.for(current_user)
    end

    # 自己的经验 / 鲸币明细，新的在前，分页
    def entries
      page = [params[:page].to_i, 0].max
      entries =
        Entry
          .where(user_id: current_user.id)
          .includes(:item)
          .order(created_at: :desc, id: :desc)
          .offset(page * ENTRIES_PER_PAGE)
          .limit(ENTRIES_PER_PAGE + 1)
          .to_a

      render json: {
               entries:
                 serialize_data(entries.first(ENTRIES_PER_PAGE), EntrySerializer, root: false),
               has_more: entries.size > ENTRIES_PER_PAGE,
             }
    end
  end
end
