# frozen_string_literal: true

RSpec.describe DiscourseKuuPoints::Account do
  fab!(:user)

  describe ".credit!" do
    it "creates the account and adds to it" do
      expect(described_class.credit!(user_id: user.id, xp: 10, coins: 5)).to eq(true)
      expect(described_class.credit!(user_id: user.id, xp: 5, coins: -2)).to eq(true)

      expect(described_class.find_by(user_id: user.id)).to have_attributes(xp: 15, coins: 3)
    end

    it "refuses to go below zero" do
      described_class.credit!(user_id: user.id, coins: 5)

      expect(described_class.credit!(user_id: user.id, coins: -6)).to eq(false)
      expect(described_class.credit!(user_id: Fabricate(:user).id, xp: -1)).to eq(false)
      expect(described_class.find_by(user_id: user.id).coins).to eq(5)
    end
  end

  describe "#level" do
    it "goes up every 200 experience and stops at 5" do
      expect([0, 199, 200, 599, 600, 800, 5000].map { |xp| described_class.new(xp:).level }).to eq(
        [1, 1, 2, 3, 4, 5, 5],
      )
    end
  end
end

RSpec.describe DiscourseKuuPoints::Entry do
  fab!(:user)

  it "records a daily task only once per day, even when two requests race" do
    args = { user_id: user.id, task: "like", task_date: Date.new(2026, 10, 22), xp: 5, coins: 3 }

    expect(described_class.record_task(**args)).to be_present
    expect(described_class.record_task(**args)).to be_nil
    expect(described_class.record_task(**args, task_date: Date.new(2026, 10, 23))).to be_present
  end
end
