# frozen_string_literal: true
require 'spec_helper'
# rubocop:disable StringLiterals

module Thredded
  describe SendWeeklyDigest do
    let(:command) { SendWeeklyDigest.new }


    let!(:user) { create(:user) }

    describe '#run' do
      subject { command.run }
      before { allow(command).to receive(:users).and_return([user]) }

      it "doesn't send a digest email by default" do
        expect { subject }.to_not change { ActionMailer::Base.deliveries.count }
      end

      context "with an error raised for a user" do
        let(:error_reporter) { double(:error_reporter, warning: nil) }
        before do
          allow(UserMailer).to receive(:weekly_digest).and_raise("Mail Error")

          allow(Thredded).to receive(:error_reporter).and_return(error_reporter)
        end

        it "calls the error reporter and doesn't halt execution" do
          subject
          expect(error_reporter).to have_received(:warning)
        end
      end

      context "with new content" do
        let!(:old_topic) { create(:topic, user: user, created_at: 2.weeks.ago) }
        let!(:new_topic) { create(:topic, user: user, created_at: 1.day.ago)}

        it "sends an digest email to all users" do
          expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        it "marks the message as sent" do
          subject
          expect(user.thredded_user_preference.last_weekly_digest_sent_at).to_not be_nil
        end
      end
    end

    describe "#users" do
      subject { command.send(:users) }

      it { should include(user) }

      context "the user has digest turned off" do
        before { create(:user_preference, user: user, send_weekly_digest: false) }

        it { should_not include(user) }
      end

      context "the user just received a digest email" do
        before { create(:user_preference, user: user, last_weekly_digest_sent_at: 1.day.ago) }

        it { should_not include(user) }
      end

      context "the user has digest turned on" do
        before { create(:user_preference, user: user, send_weekly_digest: true) }

        it { should include(user) }
      end
    end
  end
end
