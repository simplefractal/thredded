# frozen_string_literal: true
require 'spec_helper'

module Thredded
  describe AtNotificationExtractor, '.run' do
    let(:post) { build(:post) }
    let(:extractor) { AtNotificationExtractor.new(post) }

    context "with empty post" do
      let(:post) { build(:post) }
      it "returns empty list" do
        expect(extractor.run).to eq([])
      end
    end

    context "with one linked user" do
      let(:user) { create(:user, email: 'test@user.com') }
      let(:post) { build(:post, content: "attention: @[#{user.name}](#{user.id}) how goes it?") }

      it "returns the user" do
        expect(extractor.run).to eq([user])
      end
    end

  end
end
