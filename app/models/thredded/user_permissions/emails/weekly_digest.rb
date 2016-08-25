# frozen_string_literal: true
module Thredded
  module UserPermissions
    module Emails
      module WeeklyDigest
        module ClassMethods
          # @return User scope of with users
          # that should be considered for a weekly digest
          def weekly_digest_base_users
            Thredded.user_class.all
          end
        end
      end
    end
  end
end
