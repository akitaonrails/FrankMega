class CreateSharedFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :shared_files do |t|
      t.references :user, null: false, foreign_key: true
      t.string :download_hash, null: false
      t.integer :max_downloads, default: 5, null: false
      t.integer :download_count, default: 0, null: false
      t.integer :ttl_hours, default: 24, null: false
      t.datetime :expires_at, null: false
      t.string :original_filename, null: false
      t.string :content_type, null: false
      t.bigint :file_size, null: false

      t.timestamps
    end
    add_index :shared_files, :download_hash, unique: true
    add_index :shared_files, :expires_at
  end
end
