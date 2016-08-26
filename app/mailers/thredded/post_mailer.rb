# frozen_string_literal: true
require_dependency 'thredded/topic_email_view'
module Thredded
  class PostMailer < Thredded::BaseMailer
    def post_notification(post_id, emails)
      return if ENV['DISABLE_THREDDED_EMAILS']

      @post                = find_record Post, post_id
      email_details        = TopicEmailView.new(@post.postable)
      headers['X-SMTPAPI'] = email_details.smtp_api_tag('post_notification')

      mail from:     email_details.no_reply,
           to:       emails,
           cc:       email_details.no_reply,
           reply_to: email_details.reply_to,
           subject:  email_details.subject
    end

    def post_moderated(post_id)
      return if ENV['DISABLE_THREDDED_EMAILS']

      @post                = find_record Post, post_id
      email_details        = TopicEmailView.new(@post.postable)
      headers['X-SMTPAPI'] = email_details.smtp_api_tag('post_notification')

      mail from:     email_details.no_reply,
           to:       @post.user.email,
           cc:       email_details.no_reply,
           reply_to: email_details.reply_to,
           subject:  email_details.subject
    end
  end
end
