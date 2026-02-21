class AddDiskQuotaToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :disk_quota_bytes, :bigint, null: true
  end
end
