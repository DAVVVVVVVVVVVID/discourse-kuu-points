# frozen_string_literal: true

desc "上架 3 个测试用的头像框和饰品（可以重复执行，已有同名商品时跳过）"
task "kuu_points:demo_items" => :environment do
  items = DiscourseKuuPoints::DemoItems.create!
  puts "新建 #{items.size} 个测试商品：#{items.map(&:name).join("、")}"
end
