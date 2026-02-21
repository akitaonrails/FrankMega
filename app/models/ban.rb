class Ban < ApplicationRecord
  validates :ip_address, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def self.banned?(ip)
    Rails.cache.fetch("ban:#{ip}", expires_in: 1.minute) do
      active.exists?(ip_address: ip)
    end
  end

  def self.ban!(ip, reason: nil, duration: 1.hour)
    create!(
      ip_address: ip,
      reason: reason,
      expires_at: duration.from_now
    ).tap do
      Rails.cache.delete("ban:#{ip}")
    end
  end

  def active?
    expires_at > Time.current
  end
end
