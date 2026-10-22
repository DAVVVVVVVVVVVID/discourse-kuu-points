# frozen_string_literal: true

DiscourseKuuPoints::Engine.routes.draw do
  get "/summary" => "tasks#summary"
  post "/tasks/:task" => "tasks#complete", :constraints => { task: /checkin|share/ }
  get "/entries" => "shop#entries"
  post "/items/:item_id/redeem" => "items#redeem"
  put "/items/:item_id/equip" => "items#equip"
  delete "/items/:item_id/equip" => "items#unequip"
end

Discourse::Application.routes.draw do
  mount ::DiscourseKuuPoints::Engine, at: "kuu-points"
  # 鲸币商城页：.json 是页面数据，直接打开网页时交给前端路由
  get "/kuu-shop" => "discourse_kuu_points/shop#show"
end
