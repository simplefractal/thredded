# frozen_string_literal: true
module Thredded
  class Post < ActiveRecord::Base
    include PostCommon
    include ContentModerationState

    belongs_to :user,
               class_name: Thredded.user_class,
               inverse_of: :thredded_posts
    belongs_to :messageboard,
               counter_cache: true
    belongs_to :postable,
               class_name:    'Thredded::Topic',
               inverse_of:    :posts,
               counter_cache: true
    belongs_to :user_detail,
               inverse_of:    :posts,
               primary_key:   :user_id,
               foreign_key:   :user_id,
               counter_cache: true
    has_many :moderation_records,
             class_name: 'Thredded::PostModerationRecord',
             dependent: :nullify
    has_one :last_moderation_record, -> { order_newest_first },
            class_name: 'Thredded::PostModerationRecord'

    validates :messageboard_id, presence: true

    after_commit :update_parent_last_user_and_timestamp, on: [:create, :destroy]
    after_commit :auto_follow_and_notify, on: [:create, :update]

    # @param [Integer] per_page
    # @param [Thredded.user_class] user
    def page(per_page: self.class.default_per_page, user:)
      readable_posts = PostPolicy::Scope.new(user, postable.posts).resolve
      calculate_page(readable_posts, per_page)
    end

    def private_topic_post?
      false
    end

    # @return [ActiveRecord::Relation<Thredded.user_class>] users from the list of user names that can read this post.
    def readers_from_user_names(user_names)
      DbTextSearch::CaseInsensitive
        .new(Thredded.user_class.thredded_messageboards_readers([messageboard]), Thredded.user_name_column)
        .in(user_names)
    end

    private

    # Override set_default_moderation_state
    # Allow non-admins to create posts whose posts
    # depend on the topic's moderation state
    def set_default_moderation_state
      if user.present? && user.thredded_admin?
        super
      elsif postable.present?
        self.moderation_state ||= postable.moderation_state
      else
        super
      end
    end

    def auto_follow_and_notify
      return unless user
      # need to do this in-process so that it appears to them immediately
      UserTopicFollow.create_unless_exists(user.id, postable_id, :posted)
      # everything else can happen later
      AutoFollowAndNotifyJob.perform_later(id)
    end

    def update_parent_last_user_and_timestamp
      return if postable.destroyed?
      last_post = if destroyed? || !moderation_state_visible_to_all?
                    postable.posts.order_oldest_first.moderation_state_visible_to_all.select(:user_id, :updated_at).last
                  else
                    self
                  end
      if last_post
        postable.update_columns(last_user_id: last_post.user_id, updated_at: last_post.updated_at)
      else
        postable.update_columns(last_user_id: nil, updated_at: postable.created_at)
      end
    end
  end
end
