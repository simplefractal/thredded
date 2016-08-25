class AddWeeklyDigestToThreddedUserPreferences < ActiveRecord::Migration[5.0]
  def change
    add_column :thredded_user_preferences, :send_weekly_digest, :boolean, default: true, null: false
    add_column :thredded_user_preferences, :last_weekly_digest_sent_at, :datetime
  end
end
