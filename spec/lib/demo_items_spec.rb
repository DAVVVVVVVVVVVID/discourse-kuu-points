# frozen_string_literal: true

RSpec.describe DiscourseKuuPoints::DemoItems do
  before { enable_current_plugin }

  it "puts the test items on the shelf once" do
    expect(described_class.create!.map(&:name)).to eq(%w[樱花圆环 藏青双环 一朵樱花])
    expect(described_class.create!).to be_empty

    item = DiscourseKuuPoints::Item.find_by(name: "一朵樱花")
    expect(item).to have_attributes(kind: "accessory", price: 20, enabled: true)
    expect(item.upload.extension).to eq("png")
    expect(UploadReference.exists?(upload_id: item.upload_id, target: item)).to eq(true)
  end
end
