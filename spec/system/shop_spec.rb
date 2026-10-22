# frozen_string_literal: true

RSpec.describe "Coin shop" do
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[2]) }
  # 用测试商品的真图片，截图里能看到装饰：樱花圆环 30、藏青双环 50、一朵樱花（饰品）20
  let!(:demo_items) { DiscourseKuuPoints::DemoItems.create!.index_by(&:name) }
  let(:frame) { demo_items["樱花圆环"] }
  let(:accessory) { demo_items["一朵樱花"] }

  let(:dialog) { PageObjects::Components::Dialog.new }
  let(:topic_page) { PageObjects::Pages::Topic.new }

  before do
    enable_current_plugin
    SiteSetting.default_locale = "zh_CN"
  end

  # 截图给 PR 用：KUU_SCREENSHOTS=1 时存到插件的 screenshots/
  def screenshot(name)
    return if ENV["KUU_SCREENSHOTS"].blank?

    path = File.expand_path("../../screenshots/#{name}.png", __dir__)
    page.driver.with_playwright_page { |playwright| playwright.screenshot(path:, fullPage: true) }
  end

  def task(name)
    find(".kuu-points-shop__task[data-task='#{name}']")
  end

  def item(item, section)
    find(".kuu-points-shop__#{section} .kuu-points-shop__item[data-item-id='#{item.id}']")
  end

  it "asks anonymous visitors to log in" do
    visit("/kuu-shop")

    expect(page).to have_css(".kuu-points-shop__login")
    expect(page).to have_css(".kuu-points-shop__login .btn-primary")
  end

  it "checks in once a day and shows it in the history" do
    sign_in(user)
    visit("/kuu-shop")

    expect(page).to have_css(".kuu-points-shop__coins", text: "鲸币 0")
    task("checkin").find(".kuu-points-shop__checkin").click

    expect(task("checkin")).to have_css(".kuu-points-shop__checked-in", text: "已签到")
    expect(task("checkin")[:class]).to include("kuu-points-shop__task--done")
    expect(page).to have_css(".kuu-points-shop__coins", text: "鲸币 5")
    expect(page).to have_css(".kuu-points-shop__xp", text: "经验 10")
    expect(page).to have_css(".kuu-points-shop__entry", text: "签到")

    visit("/kuu-shop")
    expect(task("checkin")).to have_no_css(".kuu-points-shop__checkin")
  end

  it "redeems, wears and takes off decorations" do
    DiscourseKuuPoints::Account.credit!(user_id: user.id, xp: 230, coins: 60)
    sign_in(user)
    visit("/kuu-shop")

    item(frame, "items").find(".kuu-points-shop__redeem").click
    dialog.click_yes

    expect(item(frame, "items")).to have_css(".kuu-points-shop__item-state", text: "已拥有")
    expect(page).to have_css(".kuu-points-shop__coins", text: "鲸币 30")
    expect(page).to have_css(".kuu-points-shop__entry", text: "兑换「樱花圆环」")

    find(".kuu-points-shop__tab", text: "饰品").click
    item(accessory, "items").find(".kuu-points-shop__redeem").click
    dialog.click_yes
    expect(page).to have_css(".kuu-points-shop__coins", text: "鲸币 10")

    item(frame, "mine").find(".kuu-points-shop__equip").click
    item(accessory, "mine").find(".kuu-points-shop__equip").click

    expect(item(frame, "mine")).to have_css(".kuu-points-shop__unequip")
    expect(page).to have_css(
      ".kuu-points-shop__avatar .kuu-points-decoration--frame[src='#{frame.image_url}']",
    )
    expect(page).to have_css(".kuu-points-shop__avatar .kuu-points-decoration--accessory")
    screenshot("shop-desktop")

    item(accessory, "mine").find(".kuu-points-shop__unequip").click

    expect(item(accessory, "mine")).to have_css(".kuu-points-shop__equip")
    expect(page).to have_no_css(".kuu-points-shop__avatar .kuu-points-decoration--accessory")
    expect(DiscourseKuuPoints::Account.find_by(user_id: user.id)).to have_attributes(
      frame_item_id: frame.id,
      accessory_item_id: nil,
    )
  end

  it "does not redeem without enough coins" do
    DiscourseKuuPoints::Account.credit!(user_id: user.id, coins: 100)
    sign_in(user)
    visit("/kuu-shop")
    DiscourseKuuPoints::Account.credit!(user_id: user.id, coins: -90)

    item(frame, "items").find(".kuu-points-shop__redeem").click
    dialog.click_yes

    expect(dialog).to have_content("鲸币不够。")
    expect(DiscourseKuuPoints::UserItem.exists?(user_id: user.id)).to eq(false)
  end

  it "links to the shop from the profile tab of the user menu" do
    sign_in(user)
    visit("/")

    find(".header-dropdown-toggle.current-user").click
    find("#user-menu-button-profile").click

    expect(page).to have_css(".kuu-points-shop-link a[href='/kuu-shop']")
  end

  context "with decorations worn" do
    fab!(:topic) { Fabricate(:topic, user:) }
    fab!(:first_post) { Fabricate(:post, topic:, user:) }

    before do
      DiscourseKuuPoints::Account.credit!(user_id: user.id, xp: 450, coins: 3)
      [frame, accessory].each do |item|
        DiscourseKuuPoints::UserItem.create!(user_id: user.id, item_id: item.id)
      end
      DiscourseKuuPoints::Account.where(user_id: user.id).update_all(
        frame_item_id: frame.id,
        accessory_item_id: accessory.id,
      )
      sign_in(Fabricate(:user))
    end

    it "shows the level and the decorations on posts, the user card and the profile" do
      visit("/t/#{topic.slug}/#{topic.id}")

      post_avatar = find("#post_1 .post-avatar")
      expect(post_avatar).to have_css(".kuu-points-decoration--frame")
      expect(post_avatar).to have_css(".kuu-points-decoration--accessory")
      expect(page).to have_css("#post_1 .names .kuu-points-level", text: "Lv3")
      screenshot("post-desktop")

      topic_page.click_post_author_avatar(first_post)
      expect(page).to have_css(".user-card .user-card-avatar .kuu-points-decoration--frame")
      expect(page).to have_css(".user-card .kuu-points-level", text: "Lv3")
      screenshot("user-card-desktop")

      visit("/u/#{user.username}/summary")
      expect(page).to have_css(".user-profile-avatar .kuu-points-decoration--frame")
      expect(page).to have_css(".user-profile-names .kuu-points-level", text: "Lv3")
      screenshot("profile-desktop")
    end

    it "shows them on phones too", mobile: true do
      visit("/t/#{topic.slug}/#{topic.id}")
      expect(page).to have_css("#post_1 .kuu-points-decoration--frame")
      expect(page).to have_css("#post_1 .kuu-points-level", text: "Lv3")
      screenshot("post-mobile")

      visit("/u/#{user.username}/summary")
      expect(page).to have_css(".user-profile-avatar .kuu-points-decoration--frame")
      screenshot("profile-mobile")
    end
  end

  it "fits the shop on phones", mobile: true do
    DiscourseKuuPoints::Account.credit!(user_id: user.id, xp: 230, coins: 60)
    DiscourseKuuPoints::UserItem.create!(user_id: user.id, item_id: frame.id)
    DiscourseKuuPoints::Account.where(user_id: user.id).update_all(frame_item_id: frame.id)
    sign_in(user)
    visit("/kuu-shop")
    task("checkin").find(".kuu-points-shop__checkin").click

    expect(task("checkin")).to have_css(".kuu-points-shop__checked-in")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to eq(
      true,
    )
    screenshot("shop-mobile")
  end
end
