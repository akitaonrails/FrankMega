class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, default: "user", null: false
    add_column :users, :banned, :boolean, default: false, null: false
    add_column :users, :banned_at, :datetime
    add_column :users, :otp_secret, :string
    add_column :users, :otp_required, :boolean, default: false, null: false
  end
end
