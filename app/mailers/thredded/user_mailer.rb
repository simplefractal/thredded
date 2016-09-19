# frozen_string_literal: true
module Thredded
  class UserMailer < Thredded::BaseMailer
    def weekly_digest(user_id)
      return if ENV['DISABLE_THREDDED_EMAILS']

      @user                = find_record User, user_id
      @digest_period_in_words = "week"
      @digest_period_cutoff = digest_period_cutoff
      @messageboards = get_updated_messageboards
      email_details        = UserEmailView.new(@topic)

      # Don't send an empty messageboard
      return unless @messageboards.present?

      @user.thredded_user_preference.update_attributes!(last_weekly_digest_sent_at: Time.zone.now
      )

      mail from:     email_details.no_reply,
           to:       @user.email,
           subject:  email_details.subject
    end

    private

    # A list of messageboards that have content updated in the last
    # week that is visible to the user
    def get_updated_messageboards
       @user.thredded_can_read_messageboards.map do |messageboard|
        topics = topics_for_board(messageboard)
        {
          messageboard: messageboard,
          topics: topics,
          newly_created_topics: topics.select { |t| t.created_at > digest_period_cutoff },
          newly_posted_to_topics: topics.select { |t| t.created_at <= digest_period_cutoff }
        }
      end.select { |dict| dict[:topics].count > 0 }
    end

    def topics_for_board(messageboard)
      visible_topics = Thredded::TopicPolicy::Scope.new(@user, messageboard.topics).resolve
      visible_topics.select do |topic|
        (topic.created_at > digest_period_cutoff) ||
          topic.posts.where("created_at > ?", digest_period_cutoff).exists?
      end
    end

    def digest_period_cutoff
      @digest_period_cutoff ||= 1.week.ago
    end
  end
end
