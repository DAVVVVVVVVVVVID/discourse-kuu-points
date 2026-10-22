# frozen_string_literal: true

RSpec.describe "Daily tasks from posting and liking" do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:other_user, :user)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, user: other_user) }
  fab!(:other_post) { Fabricate(:post, topic:, user: other_user) }

  before { enable_current_plugin }

  def rewarded_tasks(for_user = user)
    DiscourseKuuPoints::Entry.where(user_id: for_user.id).order(:id).pluck(:reason)
  end

  def account(for_user = user)
    DiscourseKuuPoints::Account.find_by(user_id: for_user.id)
  end

  def new_topic
    PostCreator.create!(
      user,
      title: "今天的第 #{SecureRandom.hex(4)} 个话题",
      raw: "这是一个新的话题内容",
      category: category.id,
    )
  end

  def reply
    PostCreator.create!(user, topic_id: topic.id, raw: "这是一条普通的回复内容 #{SecureRandom.hex(4)}")
  end

  it "rewards the first topic and the first reply of the day once each" do
    first_topic = new_topic
    new_topic
    reply
    reply

    expect(rewarded_tasks).to eq(%w[topic reply])
    expect(account).to have_attributes(xp: 15, coins: 8)
    expect(DiscourseKuuPoints::Entry.find_by(user_id: user.id, reason: "topic").post_id).to eq(
      first_topic.id,
    )
  end

  it "resets at midnight Japan time" do
    freeze_time Time.utc(2026, 10, 22, 14, 59)
    reply

    freeze_time Time.utc(2026, 10, 22, 15, 0)
    reply

    expect(rewarded_tasks).to eq(%w[reply reply])
  end

  it "does not count private messages" do
    PostCreator.create!(
      user,
      title: "一封私信的标题内容",
      raw: "这是一封私信的正文内容",
      archetype: Archetype.private_message,
      target_usernames: other_user.username,
    )

    expect(rewarded_tasks).to be_empty
  end

  it "does not take rewards back when the post is deleted" do
    post = reply
    PostDestroyer.new(Discourse.system_user, post).destroy

    expect(account).to have_attributes(xp: 5, coins: 3)
  end

  it "counts topics created by plugins through PostCreator in any category" do
    PostCreator.create!(
      user,
      title: "插件直接建的话题标题",
      raw: "插件直接建的话题内容",
      category: Fabricate(:category).id,
      skip_validations: true,
    )

    expect(rewarded_tasks).to eq(%w[topic])
  end

  it "does nothing when the plugin is disabled" do
    SiteSetting.kuu_points_enabled = false
    reply

    expect(rewarded_tasks).to be_empty
  end

  it "does not reward silenced or suspended users" do
    own_reply = Fabricate(:post, topic:, user:)

    user.update!(silenced_till: 1.day.from_now)
    DiscourseKuuPoints::DailyTask.post_created(own_reply)
    user.update!(silenced_till: nil, suspended_till: 1.day.from_now, suspended_at: Time.zone.now)
    DiscourseKuuPoints::DailyTask.post_created(own_reply)

    expect(rewarded_tasks).to be_empty
  end

  describe "likes" do
    fab!(:another_post) { Fabricate(:post, topic:, user: other_user) }

    it "rewards the first like on someone else's post once a day" do
      PostActionCreator.like(user, other_post)
      PostActionCreator.like(user, another_post)

      expect(rewarded_tasks).to eq(%w[like])
      expect(account).to have_attributes(xp: 5, coins: 3)
    end

    it "does not take the reward back when the like is removed, nor give it twice" do
      PostActionCreator.like(user, other_post)
      PostActionDestroyer.destroy(user, other_post, :like)
      PostActionCreator.like(user, other_post)

      expect(rewarded_tasks).to eq(%w[like])
      expect(account).to have_attributes(xp: 5, coins: 3)
    end

    it "does not count liking one's own post" do
      own_post = Fabricate(:post, topic:, user:)
      post_action = PostAction.new(user:, post: own_post)

      DiscourseKuuPoints::DailyTask.like_created(post_action)

      expect(rewarded_tasks).to be_empty
    end
  end
end
