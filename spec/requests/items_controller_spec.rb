# frozen_string_literal: true

RSpec.describe DiscourseKuuPoints::ItemsController do
  fab!(:user)
  fab!(:frame) { Fabricate(:kuu_points_item, price: 50) }
  fab!(:other_frame) { Fabricate(:kuu_points_item, name: "藏青头像框", price: 30) }
  fab!(:accessory) { Fabricate(:kuu_points_item, name: "小鲸鱼", kind: "accessory", price: 20) }

  before { enable_current_plugin }

  def account
    DiscourseKuuPoints::Account.find_by(user_id: user.id)
  end

  def owns?(item)
    DiscourseKuuPoints::UserItem.exists?(user_id: user.id, item_id: item.id)
  end

  def give(item)
    DiscourseKuuPoints::UserItem.create!(user_id: user.id, item_id: item.id)
  end

  describe "#redeem" do
    it "requires login" do
      post "/kuu-points/items/#{frame.id}/redeem.json"

      expect(response.status).to eq(403)
    end

    it "takes the coins and keeps the item forever" do
      DiscourseKuuPoints::Account.credit!(user_id: user.id, coins: 60)
      sign_in(user)

      post "/kuu-points/items/#{frame.id}/redeem.json"

      expect(response.status).to eq(200)
      expect(account.coins).to eq(10)
      expect(owns?(frame)).to eq(true)
      expect(response.parsed_body["items"].find { |i| i["id"] == frame.id }).to include(
        "owned" => true,
        "equipped" => false,
      )
      expect(
        DiscourseKuuPoints::Entry.find_by(user_id: user.id, reason: "redeem"),
      ).to have_attributes(coins: -50, xp: 0, item_id: frame.id)
    end

    it "refuses when there are not enough coins" do
      DiscourseKuuPoints::Account.credit!(user_id: user.id, coins: 49)
      sign_in(user)

      post "/kuu-points/items/#{frame.id}/redeem.json"

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to eq([I18n.t("kuu_points.errors.not_enough_coins")])
      expect(account.coins).to eq(49)
      expect(owns?(frame)).to eq(false)
      expect(DiscourseKuuPoints::Entry.where(user_id: user.id, reason: "redeem")).to be_empty
    end

    it "refuses users without any coins" do
      sign_in(user)

      post "/kuu-points/items/#{frame.id}/redeem.json"

      expect(response.status).to eq(422)
      expect(owns?(frame)).to eq(false)
    end

    it "does not sell the same item twice" do
      DiscourseKuuPoints::Account.credit!(user_id: user.id, coins: 100)
      give(frame)
      sign_in(user)

      post "/kuu-points/items/#{frame.id}/redeem.json"

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to eq([I18n.t("kuu_points.errors.already_owned")])
      expect(account.coins).to eq(100)
    end

    it "does not sell items that are off the shelf" do
      DiscourseKuuPoints::Account.credit!(user_id: user.id, coins: 100)
      frame.update!(enabled: false)
      sign_in(user)

      post "/kuu-points/items/#{frame.id}/redeem.json"

      expect(response.status).to eq(404)
      expect(account.coins).to eq(100)
    end
  end

  describe "#equip" do
    before { sign_in(user) }

    it "wears one frame and one accessory at a time" do
      [frame, other_frame, accessory].each { |item| give(item) }

      put "/kuu-points/items/#{frame.id}/equip.json"
      put "/kuu-points/items/#{accessory.id}/equip.json"
      put "/kuu-points/items/#{other_frame.id}/equip.json"

      expect(response.status).to eq(200)
      expect(account).to have_attributes(
        frame_item_id: other_frame.id,
        accessory_item_id: accessory.id,
      )
      expect(response.parsed_body["items"].select { |i| i["equipped"] }.map { |i| i["id"] }).to(
        contain_exactly(other_frame.id, accessory.id),
      )
    end

    it "only wears items the user owns" do
      put "/kuu-points/items/#{frame.id}/equip.json"

      expect(response.status).to eq(403)
      expect(account).to be_nil
    end

    it "still wears owned items that are off the shelf" do
      give(frame)
      frame.update!(enabled: false)

      put "/kuu-points/items/#{frame.id}/equip.json"

      expect(response.status).to eq(200)
      expect(account.frame_item_id).to eq(frame.id)
    end
  end

  describe "#unequip" do
    before { sign_in(user) }

    it "takes the item off" do
      give(frame)
      give(accessory)
      put "/kuu-points/items/#{frame.id}/equip.json"
      put "/kuu-points/items/#{accessory.id}/equip.json"

      delete "/kuu-points/items/#{frame.id}/equip.json"

      expect(response.status).to eq(200)
      expect(account).to have_attributes(frame_item_id: nil, accessory_item_id: accessory.id)
    end
  end
end
