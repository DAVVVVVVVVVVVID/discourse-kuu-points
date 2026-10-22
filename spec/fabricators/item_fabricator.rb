# frozen_string_literal: true

Fabricator(:kuu_points_item, class_name: "DiscourseKuuPoints::Item") do
  name "樱花头像框"
  kind "frame"
  price 50
  upload { Fabricate(:image_upload) }
end
