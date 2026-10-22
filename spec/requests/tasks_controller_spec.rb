# frozen_string_literal: true

RSpec.describe DiscourseKuuPoints::TasksController do
  fab!(:user)

  before { enable_current_plugin }

  def account
    DiscourseKuuPoints::Account.find_by(user_id: user.id)
  end

  describe "#complete" do
    it "requires login" do
      post "/kuu-points/tasks/checkin.json"

      expect(response.status).to eq(403)
    end

    it "is not available when the plugin is disabled" do
      SiteSetting.kuu_points_enabled = false
      sign_in(user)

      post "/kuu-points/tasks/checkin.json"

      expect(response.status).to eq(404)
    end

    it "rewards the check-in once a day" do
      sign_in(user)

      post "/kuu-points/tasks/checkin.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("rewarded" => true, "xp" => 10, "coins" => 5)
      expect(response.parsed_body["summary"]).to include("xp" => 10, "coins" => 5, "level" => 1)

      post "/kuu-points/tasks/checkin.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["rewarded"]).to eq(false)
      expect(account).to have_attributes(xp: 10, coins: 5)
      expect(DiscourseKuuPoints::Entry.where(user_id: user.id, reason: "checkin").count).to eq(1)
    end

    it "starts a new day at midnight Japan time" do
      sign_in(user)
      freeze_time Time.utc(2026, 10, 22, 14, 59)

      post "/kuu-points/tasks/checkin.json"
      post "/kuu-points/tasks/share.json"

      freeze_time Time.utc(2026, 10, 22, 15, 0)

      post "/kuu-points/tasks/checkin.json"
      expect(response.parsed_body["rewarded"]).to eq(true)

      post "/kuu-points/tasks/share.json"
      expect(response.parsed_body["rewarded"]).to eq(true)

      expect(account).to have_attributes(xp: 30, coins: 16)
      expect(
        DiscourseKuuPoints::Entry.where(user_id: user.id).order(:id).pluck(:reason, :task_date),
      ).to eq(
        [
          ["checkin", Date.new(2026, 10, 22)],
          ["share", Date.new(2026, 10, 22)],
          ["checkin", Date.new(2026, 10, 23)],
          ["share", Date.new(2026, 10, 23)],
        ],
      )
    end

    it "uses the amounts from the site settings" do
      SiteSetting.kuu_points_share_xp = 7
      SiteSetting.kuu_points_share_coins = 0
      sign_in(user)

      post "/kuu-points/tasks/share.json"

      expect(response.parsed_body).to include("rewarded" => true, "xp" => 7, "coins" => 0)
      expect(account).to have_attributes(xp: 7, coins: 0)
    end

    it "does not let the client complete tasks that come from posting or liking" do
      sign_in(user)

      post "/kuu-points/tasks/like.json"

      expect(response.status).to eq(404)
      expect(account).to be_nil
    end

    it "does not reward silenced users" do
      user.update!(silenced_till: 1.day.from_now)
      sign_in(user)

      post "/kuu-points/tasks/checkin.json"

      expect(response.status).to eq(403)
      expect(account).to be_nil
    end
  end

  describe "#summary" do
    it "requires login" do
      get "/kuu-points/summary.json"

      expect(response.status).to eq(403)
    end

    it "shows a new user at level 1 with no tasks done" do
      sign_in(user)

      get "/kuu-points/summary.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "level" => 1,
        "max_level" => 5,
        "xp" => 0,
        "next_level_xp" => 200,
        "coins" => 0,
      )
      expect(response.parsed_body["tasks"].map { |t| [t["task"], t["done"]] }).to eq(
        [["checkin", false], ["topic", false], ["reply", false], ["like", false], ["share", false]],
      )
    end

    it "shows today's finished tasks and the progress to the next level" do
      DiscourseKuuPoints::Account.credit!(user_id: user.id, xp: 790, coins: 3)
      sign_in(user)
      post "/kuu-points/tasks/checkin.json"

      get "/kuu-points/summary.json"

      expect(response.parsed_body).to include(
        "level" => 5,
        "xp" => 800,
        "next_level_xp" => nil,
        "coins" => 8,
      )
      expect(response.parsed_body["tasks"].first).to eq(
        "task" => "checkin",
        "done" => true,
        "xp" => 10,
        "coins" => 5,
      )
    end
  end
end
