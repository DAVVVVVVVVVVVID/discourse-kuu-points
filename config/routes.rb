# frozen_string_literal: true

DiscourseKuuPoints::Engine.routes.draw do
  get "/summary" => "tasks#summary"
  post "/tasks/:task" => "tasks#complete", :constraints => { task: /checkin|share/ }
  get "/entries" => "shop#entries"
  post "/items/:item_id/redeem" => "items#redeem"
  put "/items/:item_id/equip" => "items#equip"
  delete "/items/:item_id/equip" => "items#unequip"

  scope "/admin", constraints: AdminConstraint.new do
    get "/items" => "admin/items#index"
    post "/items" => "admin/items#create"
    put "/items/:item_id" => "admin/items#update"
    get "/accounts/:username" => "admin/accounts#show",
        :constraints => {
          username: RouteFormat.username,
        }
    post "/accounts/:username/adjust" => "admin/accounts#adjust",
         :constraints => {
           username: RouteFormat.username,
         }
  end
end

Discourse::Application.routes.draw do
  mount ::DiscourseKuuPoints::Engine, at: "kuu-points"
  # 鲸币商城页：.json 是页面数据，直接打开网页时交给前端路由
  get "/kuu-shop" => "discourse_kuu_points/shop#show"
  # 后台的「商品」「调整」页直接打开或刷新时
  get "/admin/plugins/discourse-kuu-points/items" => "admin/plugins#index",
      :constraints => AdminConstraint.new
  get "/admin/plugins/discourse-kuu-points/adjust" => "admin/plugins#index",
      :constraints => AdminConstraint.new
end
