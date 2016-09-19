# frozen_string_literal: true
module Thredded
  class UserEmailView
    attr_accessor :user

    # @param [Thredded::user_class] user
    def initialize(user)
      @user = user
    end

    def subject
      "#{Thredded.email_outgoing_prefix} Weekly Digest"
    end

    def no_reply
      Thredded.email_from
    end

    def to
      user.email
    end
  end
end
