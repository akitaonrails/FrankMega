class CreateAllowedMimeTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :allowed_mime_types do |t|
      t.string :mime_type, null: false
      t.string :description
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end
    add_index :allowed_mime_types, :mime_type, unique: true
  end
end
