# frozen_string_literal: true
module Thredded
  class SendWeeklyDigest
    def run
      # Wrap these in a try clause so a single fail doesn't kill all of them
      users.each do |user|
        # record that we've message them
        # compile digest information
        # send the mail
        UserMailer.weekly_digest(user.id).deliver_now
      end
    end

    private

    def users
      @users ||= begin
        Thredded.user_class.includes(:thredded_user_preference).where(
          'thredded_user_preferences.send_weekly_digest' => [true, nil]
          ).all.reject do |user|
            user.thredded_user_preference.received_last_weekly_digest_recently?(resend_safety_time)
        end
      end
    end

    def resend_safety_time
      2.days.ago
    end
  end
end
