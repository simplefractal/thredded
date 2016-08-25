# frozen_string_literal: true
module Thredded
  class SendWeeklyDigest
    def run
      users.each do |user|
        begin
          UserMailer.weekly_digest(user.id).deliver_now
        rescue => e
          Thredded.error_reporter.warning(e)
          p "Skipping user #{user.id}: #{e}"
        end
      end
    end

    private

    def users
      @users ||= begin
        Thredded.user_class.weekly_digest_base_users.includes(:thredded_user_preference).where(
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
