class CreateBans < ActiveRecord::Migration[8.1]
  def change
    create_table :bans do |t|
      t.string :ip_address, null: false
      t.string :reason
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :bans, :ip_address
    add_index :bans, :expires_at
  end
end
