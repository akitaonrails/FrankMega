class Ban < ApplicationRecord
  validates :ip_address, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def self.banned?(ip)
    active.exists?(ip_address: ip)
  end

  def self.ban!(ip, reason: nil, duration: 1.hour)
    create!(
      ip_address: ip,
      reason: reason,
      expires_at: duration.from_now
    )
  end

  def active?
    expires_at > Time.current
  end
end
