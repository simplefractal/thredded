# frozen_string_literal: true
module Thredded
  module ModeratePost
    module_function

    # @param [Post] post
    # @param [Symbol] moderation_state
    # @param [Thredded.user_class] moderator
    # @return [Thredded::PostModerationRecord]
    def run!(post:, moderation_state:, moderator:)
      post_moderation_record = nil
      Thredded::Post.transaction do
        post_moderation_record = Thredded::PostModerationRecord.record!(
          moderator: moderator,
          post: post,
          previous_moderation_state: post.moderation_state,
          moderation_state: moderation_state,
        )

        if post.postable.first_post == post
          update_without_timestamping!(post.postable, moderation_state: moderation_state)

          if moderation_state == :blocked
            post.postable.posts.where(user_id: post.user.id).where.not(id: post.id).each do |a_post|
              a_post.skip_auto_follow_and_notify = true
              update_without_timestamping!(a_post, moderation_state: moderation_state)
            end
          end
        end
        post.skip_auto_follow_and_notify = true
        update_without_timestamping!(post, moderation_state: moderation_state)
        notify_poster_of_moderation_state(post)
        post_moderation_record
      end
      post_moderation_record
    end

    # @param record [ActiveRecord]
    # @api private
    def update_without_timestamping!(record, *attr)
      record_timestamps_was = record.record_timestamps
      begin
        record.record_timestamps = false
        record.update!(*attr)
      ensure
        record.record_timestamps = record_timestamps_was
      end
    end

    def notify_poster_of_moderation_state(post)
      PostMailer.post_moderated(post.id, users_to_email(post)).deliver_now
    end

    def users_to_email(post)
      post.postable.following_users.reject { |u| u.thredded_admin? }.map(&:email)
    end
  end
end
