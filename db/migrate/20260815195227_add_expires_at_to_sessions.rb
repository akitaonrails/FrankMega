class AddExpiresAtToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :expires_at, :datetime
    reversible do |dir|
      dir.up { execute "UPDATE sessions SET expires_at = datetime(created_at, '+30 days')" }
    end
    change_column_null :sessions, :expires_at, false
    add_index :sessions, :expires_at
  end
end
