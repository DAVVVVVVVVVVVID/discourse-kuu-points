# frozen_string_literal: true

RSpec.describe DiscourseKuuPoints::ShopController do
  fab!(:user)
  fab!(:frame) { Fabricate(:kuu_points_item, position: 2) }
  fab!(:accessory) { Fabricate(:kuu_points_item, name: "小鲸鱼", kind: "accessory", position: 1) }
  fab!(:retired) { Fabricate(:kuu_points_item, name: "旧头像框", enabled: false) }
  fab!(:retired_owned) { Fabricate(:kuu_points_item, name: "限定头像框", enabled: false, position: 0) }

  before { enable_current_plugin }

  describe "#show" do
    it "asks anonymous users to log in" do
      get "/kuu-shop.json"

      expect(response.status).to eq(403)
    end

    it "lets anonymous visitors open the page, which then asks them to log in" do
      get "/kuu-shop"

      expect(response.status).to eq(200)
    end

    it "lists the items on sale and the user's own items" do
      DiscourseKuuPoints::UserItem.create!(user_id: user.id, item_id: retired_owned.id)
      sign_in(user)

      get "/kuu-shop.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["summary"]).to include("level" => 1, "coins" => 0)
      expect(response.parsed_body["items"].map { |i| [i["name"], i["enabled"], i["owned"]] }).to eq(
        [["限定头像框", false, true], ["小鲸鱼", true, false], ["樱花头像框", true, false]],
      )
      expect(response.parsed_body["items"].second["image_url"]).to eq(accessory.upload.url)
    end
  end

  describe "#entries" do
    it "requires login" do
      get "/kuu-points/entries.json"

      expect(response.status).to eq(403)
    end

    it "pages through the user's own records, newest first" do
      other_user = Fabricate(:user)
      DiscourseKuuPoints::Entry.create!(user_id: other_user.id, reason: "checkin", xp: 10)
      22.times do |i|
        DiscourseKuuPoints::Entry.create!(
          user_id: user.id,
          reason: "checkin",
          xp: 10,
          coins: 5,
          created_at: i.days.ago,
        )
      end
      DiscourseKuuPoints::Entry.create!(
        user_id: user.id,
        reason: "redeem",
        coins: -50,
        item: frame,
        created_at: 1.minute.from_now,
      )
      sign_in(user)

      get "/kuu-points/entries.json"

      expect(response.parsed_body["entries"].size).to eq(20)
      expect(response.parsed_body["entries"].first).to include(
        "reason" => "redeem",
        "coins" => -50,
        "item_name" => "樱花头像框",
      )
      expect(response.parsed_body["has_more"]).to eq(true)

      get "/kuu-points/entries.json", params: { page: 1 }

      expect(response.parsed_body["entries"].size).to eq(3)
      expect(response.parsed_body["has_more"]).to eq(false)
    end
  end
end
