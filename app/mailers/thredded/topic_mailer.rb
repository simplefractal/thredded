# frozen_string_literal: true
require_dependency 'thredded/topic_email_view'
module Thredded
  class TopicMailer < Thredded::BaseMailer
    def topic_created(topic_id)
      return if ENV['DISABLE_THREDDED_EMAILS']

      @topic                = find_record Topic, topic_id
      email_details        = TopicEmailView.new(@topic)
      headers['X-SMTPAPI'] = email_details.smtp_api_tag('post_notification')

      mail from:     email_details.no_reply,
           to:       email_details.no_reply,
           reply_to: email_details.reply_to,
           subject:  email_details.subject
    end

    # Broadcast via email to all messageboard viewers that
    # this topic has been created
    def topic_created_broadcast(topic_id)
      return if ENV['DISABLE_THREDDED_EMAILS']

      @topic                = find_record Topic, topic_id
      email_details        = TopicEmailView.new(@topic)
      headers['X-SMTPAPI'] = email_details.smtp_api_tag('post_notification')

      # send to all users who can see this board except for admin users
      # The admins will see it because of the TO field
      emails = Thredded.user_class.thredded_messageboards_readers(
          [@topic.messageboard]
        ).reject { |u| u.thredded_admin? }.map(&:email)

      mail from:     email_details.no_reply,
           cc:       email_details.no_reply,
           reply_to: email_details.reply_to,
           subject:  email_details.subject,
           to:       emails
    end
  end
end
