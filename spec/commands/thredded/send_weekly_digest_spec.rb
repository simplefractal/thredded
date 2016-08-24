# frozen_string_literal: true
require 'spec_helper'
# rubocop:disable StringLiterals

module Thredded
  describe SendWeeklyDigest do
    describe '#run' do
      subject { command.run }
      let(:command) { SendWeeklyDigest.new }

      let!(:old_topic) { create(:topic, user: user, created_at: 2.weeks.ago) }
      let!(:new_topic) { create(:topic, user: user, created_at: 1.day.ago)}
      let!(:user) { create(:user) }

      before { allow(command).to receive(:users).and_return([user]) }

      it "sends an digest email to all users" do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end
