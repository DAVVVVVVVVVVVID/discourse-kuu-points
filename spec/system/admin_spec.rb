# frozen_string_literal: true

RSpec.describe "Admin pages for points and coins" do
  fab!(:admin)
  fab!(:user)

  let(:modal) { PageObjects::Modals::Base.new }
  let(:image) do
    File.expand_path("../../lib/discourse_kuu_points/demo_items/navy-frame.png", __dir__)
  end

  before do
    enable_current_plugin
    SiteSetting.default_locale = "zh_CN"
    sign_in(admin)
  end

  # 截图给 PR 用：KUU_SCREENSHOTS=1 时存到插件的 screenshots/
  def screenshot(name)
    return if ENV["KUU_SCREENSHOTS"].blank?

    path = File.expand_path("../../screenshots/#{name}.png", __dir__)
    page.driver.with_playwright_page { |playwright| playwright.screenshot(path:, fullPage: true) }
  end

  it "adds an item with an image, then edits it and takes it off the shelf" do
    visit("/admin/plugins/discourse-kuu-points/items")

    find(".kuu-points-admin__new-item").click
    form = PageObjects::Components::FormKit.new(".kuu-points-item-form .form-kit")
    form.field("name").fill_in("藏青双环")
    form.field("kind").select("frame")
    within(".kuu-points-item-form") { attach_file(image, make_visible: true) }
    expect(page).to have_css(".kuu-points-item-form .form-kit__control-image .btn-danger")
    form.field("price").fill_in("80")
    screenshot("admin-item-form-desktop")
    form.submit

    expect(modal).to be_closed
    item = DiscourseKuuPoints::Item.find_by(name: "藏青双环")
    expect(item).to have_attributes(kind: "frame", price: 80, enabled: true)
    expect(page).to have_css(".kuu-points-admin__item[data-item-id='#{item.id}']", text: "上架中")

    find(".kuu-points-admin__item[data-item-id='#{item.id}'] .kuu-points-admin__edit").click
    form.field("price").fill_in("60")
    form.field("enabled").toggle
    form.submit

    expect(page).to have_css(".kuu-points-admin__item--disabled", text: "已下架")
    expect(item.reload).to have_attributes(price: 60, enabled: false)
    screenshot("admin-items-desktop")
  end

  it "adjusts a user's experience and coins with a reason" do
    DiscourseKuuPoints::Account.credit!(user_id: user.id, xp: 100, coins: 10)
    visit("/admin/plugins/discourse-kuu-points/adjust")

    lookup = PageObjects::Components::FormKit.new(".kuu-points-admin-adjust > .form-kit")
    lookup.field("username").fill_in(user.username)
    lookup.submit
    expect(page).to have_css(".kuu-points-admin-adjust__summary", text: "Lv1，经验 100，鲸币 10")

    adjust = PageObjects::Components::FormKit.new(".kuu-points-admin-adjust__account .form-kit")
    adjust.field("xp").fill_in("150")
    adjust.field("coins").fill_in("4")
    adjust.field("note").fill_in("线下活动奖励")
    adjust.submit

    expect(page).to have_css(".kuu-points-admin-adjust__summary", text: "Lv2，经验 250，鲸币 14")
    expect(page).to have_css(".kuu-points-admin-adjust__entry", text: "管理员调整：线下活动奖励")
    screenshot("admin-adjust-desktop")
    expect(DiscourseKuuPoints::Account.find_by(user_id: user.id)).to have_attributes(
      xp: 250,
      coins: 14,
    )
  end
end
