# frozen_string_literal: true

module DiscourseKuuPoints
  # 管理员手动给用户加减经验 / 鲸币。必须填原因：记进明细（用户能看到），也记进管理员操作日志。
  # 扣到负数时不改
  class Account::Adjust
    include Service::Base

    params do
      attribute :username, :string
      attribute :xp, :integer, default: 0
      attribute :coins, :integer, default: 0
      attribute :note, :string

      validates :username, presence: true
      validates :note, presence: true, length: { maximum: 500 }
      validates :xp, :coins, numericality: { only_integer: true, in: -100_000..100_000 }
      validate { errors.add(:base, :blank) if xp.to_i == 0 && coins.to_i == 0 }
    end

    policy :admin
    model :user

    transaction do
      step :credit
      step :record_entry
    end

    step :log_action

    private

    def admin(guardian:)
      guardian.is_admin?
    end

    def fetch_user(params:)
      User.find_by_username(params.username)
    end

    def credit(user:, params:)
      if !Account.credit!(user_id: user.id, xp: params.xp, coins: params.coins)
        fail!("would go below zero")
      end
    end

    def record_entry(guardian:, user:, params:)
      context[:entry] = Entry.create!(
        user:,
        reason: "adjust",
        xp: params.xp,
        coins: params.coins,
        note: params.note,
        acting_user: guardian.user,
      )
    end

    def log_action(guardian:, user:, params:)
      StaffActionLogger.new(guardian.user).log_custom(
        "kuu_points_adjust",
        { username: user.username, xp: params.xp, coins: params.coins, note: params.note },
      )
    end
  end
end
