# frozen_string_literal: true

module DiscourseKuuPoints
  class EntrySerializer < ApplicationSerializer
    attributes :id, :reason, :xp, :coins, :note, :item_name, :created_at

    def item_name
      object.item&.name
    end

    def include_item_name?
      object.item_id.present?
    end
  end
end
