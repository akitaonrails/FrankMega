class AddLastOtpAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_otp_at, :datetime
  end
end
