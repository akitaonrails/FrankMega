class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :webauthn_credentials, dependent: :destroy
  has_many :created_invitations, class_name: "Invitation", foreign_key: :created_by_id, dependent: :nullify, inverse_of: :created_by
  has_many :shared_files, dependent: :destroy

  encrypts :otp_secret

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: %w[admin user] }

  scope :admins, -> { where(role: "admin") }
  scope :active, -> { where(banned: false) }

  def admin?
    role == "admin"
  end

  def banned?
    banned
  end

  def ban!
    update!(banned: true, banned_at: Time.current)
    sessions.destroy_all
  end

  def unban!
    update!(banned: false, banned_at: nil)
  end

  def otp_provisioning_uri(issuer: "FrankMega")
    return nil unless otp_secret.present?
    totp = ROTP::TOTP.new(otp_secret, issuer: issuer)
    totp.provisioning_uri(email_address)
  end

  def verify_otp(code)
    return false unless otp_secret.present?
    totp = ROTP::TOTP.new(otp_secret)
    totp.verify(code, drift_behind: 30, drift_ahead: 30).present?
  end

  def generate_otp_secret!
    update!(otp_secret: ROTP::Base32.random)
  end

  def enable_otp!
    update!(otp_required: true)
  end

  def disable_otp!
    update!(otp_secret: nil, otp_required: false)
  end

  def has_passkeys?
    webauthn_credentials.exists?
  end
end
