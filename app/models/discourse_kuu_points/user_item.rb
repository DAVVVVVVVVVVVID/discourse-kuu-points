# frozen_string_literal: true

module DiscourseKuuPoints
  # 用户兑换到的商品，永久拥有
  class UserItem < ActiveRecord::Base
    self.table_name = "kuu_points_user_items"

    belongs_to :user
    belongs_to :item
  end
end

# == Schema Information
#
# Table name: kuu_points_user_items
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  item_id    :bigint           not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_kuu_points_user_items_on_user_id_and_item_id  (user_id,item_id) UNIQUE
#
