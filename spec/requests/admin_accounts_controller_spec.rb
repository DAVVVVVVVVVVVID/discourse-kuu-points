# frozen_string_literal: true

RSpec.describe DiscourseKuuPoints::Admin::AccountsController do
  fab!(:admin)
  fab!(:user)

  before { enable_current_plugin }

  def account
    DiscourseKuuPoints::Account.find_by(user_id: user.id)
  end

  def adjust(params)
    post "/kuu-points/admin/accounts/#{user.username}/adjust.json", params:
  end

  it "is only for admins" do
    sign_in(Fabricate(:moderator))

    adjust(xp: 10, note: "活动奖励")

    expect(response.status).to eq(404)
    expect(account).to be_nil
  end

  context "as an admin" do
    before { sign_in(admin) }

    it "shows the user's account and recent records" do
      DiscourseKuuPoints::Account.credit!(user_id: user.id, xp: 210, coins: 7)

      get "/kuu-points/admin/accounts/#{user.username}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["user"]["username"]).to eq(user.username)
      expect(response.parsed_body["summary"]).to include("level" => 2, "xp" => 210, "coins" => 7)
    end

    it "adds and takes away experience and coins with a reason the user can see" do
      adjust(xp: 50, coins: 20, note: "新年活动奖励")
      adjust(coins: -5, note: "误发回收")

      expect(response.status).to eq(200)
      expect(account).to have_attributes(xp: 50, coins: 15)
      expect(response.parsed_body["entries"].first).to include(
        "reason" => "adjust",
        "coins" => -5,
        "note" => "误发回收",
        "acting_username" => admin.username,
      )
      expect(
        UserHistory.where(custom_type: "kuu_points_adjust", acting_user_id: admin.id).count,
      ).to eq(2)

      sign_in(user)
      get "/kuu-points/entries.json"
      expect(response.parsed_body["entries"].map { |e| e["note"] }).to eq(%w[误发回收 新年活动奖励])
    end

    it "requires a reason and a change" do
      adjust(xp: 10, note: "")
      expect(response.status).to eq(400)

      adjust(xp: 0, coins: 0, note: "什么也不改")
      expect(response.status).to eq(400)

      expect(DiscourseKuuPoints::Entry.count).to eq(0)
    end

    it "does not take more than the user has" do
      DiscourseKuuPoints::Account.credit!(user_id: user.id, coins: 5)

      adjust(coins: -6, note: "扣多了")

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to eq([I18n.t("kuu_points.errors.below_zero")])
      expect(account.coins).to eq(5)
      expect(DiscourseKuuPoints::Entry.where(reason: "adjust")).to be_empty
      expect(UserHistory.where(custom_type: "kuu_points_adjust")).to be_empty
    end

    it "404s for unknown users" do
      post "/kuu-points/admin/accounts/nobody/adjust.json", params: { xp: 1, note: "试试" }

      expect(response.status).to eq(404)
    end
  end
end
