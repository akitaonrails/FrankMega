class Invitation < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :used_by, class_name: "User", optional: true

  validates :code, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_code, on: :create

  scope :pending, -> { where(used_by_id: nil).where("expires_at > ?", Time.current) }
  scope :used, -> { where.not(used_by_id: nil) }
  scope :expired, -> { where(used_by_id: nil).where("expires_at <= ?", Time.current) }

  def pending?
    used_by_id.nil? && expires_at > Time.current
  end

  def used?
    used_by_id.present?
  end

  def expired?
    used_by_id.nil? && expires_at <= Time.current
  end

  def status
    return "used" if used?
    return "expired" if expired?
    "pending"
  end

  def redeem!(user)
    update!(used_by: user, used_at: Time.current)
  end

  private

  def generate_code
    self.code ||= SecureRandom.urlsafe_base64(16)
  end
end
