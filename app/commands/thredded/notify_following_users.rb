# frozen_string_literal: true
module Thredded
  class NotifyFollowingUsers
    def initialize(post)
      @post = post
    end

    def run
      # Don't send a notification for the first post
      # because we send that in the topic creator
      return if @post.postable.posts.count == 1

      PostMailer.post_notification(@post.id, targeted_users.map(&:email)).deliver_now
      MembersMarkedNotified.new(@post, targeted_users).run
    end

    def targeted_users
      @targeted_users ||= @post.postable.following_users.reject { |u| (u == @post.user) || u.thredded_admin? }
    end
  end
end
