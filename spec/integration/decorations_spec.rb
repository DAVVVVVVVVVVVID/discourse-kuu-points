# frozen_string_literal: true

RSpec.describe "Levels and avatar decorations" do
  # 没发过帖、信任等级不到 2 的用户，主页对别人是隐藏的（core 的 hide_new_user_profiles）
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  fab!(:viewer, :user)
  fab!(:frame, :kuu_points_item)
  fab!(:accessory) { Fabricate(:kuu_points_item, name: "小鲸鱼", kind: "accessory") }
  fab!(:topic) { Fabricate(:topic, user:) }
  fab!(:first_post) { Fabricate(:post, topic:, user:) }
  fab!(:reply) { Fabricate(:post, topic:, user: viewer) }

  before do
    enable_current_plugin
    DiscourseKuuPoints::Account.credit!(user_id: user.id, xp: 450)
    [frame, accessory].each do |item|
      DiscourseKuuPoints::UserItem.create!(user_id: user.id, item_id: item.id)
    end
    DiscourseKuuPoints::Account.where(user_id: user.id).update_all(
      frame_item_id: frame.id,
      accessory_item_id: accessory.id,
    )
    sign_in(viewer)
  end

  let(:decorated) do
    { "level" => 3, "frame_url" => frame.upload.url, "accessory_url" => accessory.upload.url }
  end

  it "shows them on posts" do
    get "/t/#{topic.id}.json"

    posts = response.parsed_body["post_stream"]["posts"]
    expect(posts.map { |p| p["kuu_points"] }).to eq(
      [decorated, { "level" => 1, "frame_url" => nil, "accessory_url" => nil }],
    )
  end

  it "does not query the decorations once per post" do
    5.times { Fabricate(:post, topic:, user: Fabricate(:user)) }
    get "/t/#{topic.id}.json"

    queries = track_sql_queries { get "/t/#{topic.id}.json" }

    expect(queries.count { |sql| sql.include?("kuu_points_accounts") }).to eq(1)
  end

  it "shows them on the user card and the profile" do
    get "/u/#{user.username}/card.json"
    expect(response.parsed_body["user"]["kuu_points"]).to eq(decorated)

    get "/u/#{user.username}.json"
    expect(response.parsed_body["user"]["kuu_points"]).to eq(decorated)
  end

  it "shows nothing when the plugin is disabled" do
    SiteSetting.kuu_points_enabled = false

    get "/u/#{user.username}/card.json"

    expect(response.parsed_body["user"]).not_to have_key("kuu_points")
  end
end
