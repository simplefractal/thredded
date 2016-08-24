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
      # TODO allow them to unsubscribe from this
      @users ||= Thredded.user_class.all
    end
  end
end
