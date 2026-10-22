# frozen_string_literal: true

module DiscourseKuuPoints
  # 等级 1–5，每 200 经验升一级，5 级封顶（Issue #1 第 1 条）。和 core 的信任等级无关
  module Level
    XP_PER_LEVEL = 200
    MAX = 5

    def self.for(xp)
      [xp / XP_PER_LEVEL + 1, MAX].min
    end

    # 升到下一级要的总经验；满级是 nil
    def self.next_level_xp(xp)
      level = self.for(xp)
      level * XP_PER_LEVEL if level < MAX
    end
  end
end
