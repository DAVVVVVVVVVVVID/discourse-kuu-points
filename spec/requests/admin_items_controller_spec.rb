# frozen_string_literal: true

RSpec.describe DiscourseKuuPoints::Admin::ItemsController do
  fab!(:admin)
  fab!(:moderator)
  fab!(:user)
  fab!(:upload, :image_upload)
  fab!(:item) { Fabricate(:kuu_points_item, name: "樱花圆环", price: 30) }

  before { enable_current_plugin }

  let(:new_item) { { name: "小鲸鱼", kind: "accessory", upload_id: upload.id, price: 40 } }

  it "is only for admins" do
    [user, moderator].each do |someone|
      sign_in(someone)

      get "/kuu-points/admin/items.json"
      expect(response.status).to eq(404)

      post "/kuu-points/admin/items.json", params: new_item
      expect(response.status).to eq(404)
    end

    expect(DiscourseKuuPoints::Item.count).to eq(1)
  end

  context "as an admin" do
    before { sign_in(admin) }

    it "lists every item with how many people own it" do
      item.update!(enabled: false)
      DiscourseKuuPoints::UserItem.create!(user_id: user.id, item_id: item.id)

      get "/kuu-points/admin/items.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["items"]).to contain_exactly(
        include("id" => item.id, "enabled" => false, "owners_count" => 1),
      )
    end

    it "adds an item and logs it" do
      post "/kuu-points/admin/items.json", params: new_item

      expect(response.status).to eq(200)
      created = DiscourseKuuPoints::Item.find_by(name: "小鲸鱼")
      expect(created).to have_attributes(kind: "accessory", price: 40, enabled: true, upload:)
      expect(
        UserHistory.where(custom_type: "kuu_points_item_create", acting_user_id: admin.id),
      ).to exist
    end

    it "edits an item and takes it off the shelf, but keeps its kind" do
      put "/kuu-points/admin/items/#{item.id}.json",
          params: {
            name: "樱花圆环（限定）",
            kind: "accessory",
            upload_id: item.upload_id,
            price: 60,
            enabled: false,
            position: 3,
          }

      expect(response.status).to eq(200)
      expect(item.reload).to have_attributes(
        name: "樱花圆环（限定）",
        kind: "frame",
        price: 60,
        enabled: false,
        position: 3,
      )
      expect(UserHistory.where(custom_type: "kuu_points_item_update")).to exist
    end

    it "rejects incomplete items" do
      post "/kuu-points/admin/items.json", params: new_item.merge(name: "", price: -1)

      expect(response.status).to eq(400)
    end

    it "rejects missing images" do
      post "/kuu-points/admin/items.json", params: new_item.merge(upload_id: 0)

      expect(response.status).to eq(422)
      expect(DiscourseKuuPoints::Item.count).to eq(1)
    end
  end
end
