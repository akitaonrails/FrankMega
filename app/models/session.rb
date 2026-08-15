class Session < ApplicationRecord
  belongs_to :user

  validates :expires_at, presence: true
end
