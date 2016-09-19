class AddEmailAllMessageboardMembersToThreddedTopics < ActiveRecord::Migration[5.0]
  def change
    add_column :thredded_topics, :email_all_messageboard_members, :boolean, default: false, null: false
  end
end
