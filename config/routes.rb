# frozen_string_literal: true

DiscourseKuuPoints::Engine.routes.draw do
  get "/summary" => "tasks#summary"
  post "/tasks/:task" => "tasks#complete", :constraints => { task: /checkin|share/ }
end

Discourse::Application.routes.draw { mount ::DiscourseKuuPoints::Engine, at: "kuu-points" }
