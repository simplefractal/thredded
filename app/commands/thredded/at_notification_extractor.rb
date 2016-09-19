# frozen_string_literal: true
require_dependency 'html/pipeline/at_mention_filter'
module Thredded
  class AtNotificationExtractor
    def initialize(post)
      @post = post
    end

    # @return [Array<Thredded.user_class>]
    def run
      view_context = Thredded::ApplicationController.new.view_context
      # Do not highlight @-mentions at first, because:
      # * When parsing, @-mentions within <a> tags will not be considered.
      # * We can't always generate the user URL here because request.host is not available.
      html = @post.filtered_content(view_context, users_provider: nil)

      user_identifiers = @post.content.scan(/\@\[(.+?)\]\(\w*\)/).flatten
      Thredded.user_class.thredded_messageboards_readers([@post.messageboard]).where(Thredded.user_name_column => user_identifiers)
    end
  end
end
