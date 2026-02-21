class SharedFile < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  before_validation :generate_download_hash, on: :create
  before_validation :set_expiry, on: :create

  validates :download_hash, presence: true, uniqueness: true
  validates :max_downloads, presence: true, numericality: { in: 1..10 }
  validates :download_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :ttl_hours, presence: true, numericality: { in: 1..24 }
  validates :expires_at, presence: true
  validates :original_filename, presence: true
  validates :content_type, presence: true
  validates :file_size, presence: true, numericality: { less_than_or_equal_to: 1.gigabyte }
  validate :file_type_allowed, on: :create
  validate :file_attached
  validate :within_user_quota, on: :create

  scope :active, -> { where("expires_at > ? AND download_count < max_downloads", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :exhausted, -> { where("download_count >= max_downloads") }
  scope :inactive, -> { where("expires_at <= ? OR download_count >= max_downloads", Time.current) }

  def active?
    expires_at > Time.current && download_count < max_downloads
  end

  def expired?
    expires_at <= Time.current
  end

  def exhausted?
    download_count >= max_downloads
  end

  def downloads_remaining
    [ max_downloads - download_count, 0 ].max
  end

  def time_remaining
    remaining = expires_at - Time.current
    remaining.positive? ? remaining : 0
  end

  def increment_download!
    # Atomic: only increments if still under the limit, returns true on success
    self.class.where(id: id)
        .where("download_count < max_downloads")
        .where("expires_at > ?", Time.current)
        .update_all("download_count = download_count + 1") == 1
  end

  def download_url_path
    "/d/#{download_hash}"
  end

  private

  def generate_download_hash
    self.download_hash ||= SecureRandom.urlsafe_base64(24)
  end

  def set_expiry
    self.expires_at ||= ttl_hours.to_i.hours.from_now
  end

  def file_type_allowed
    return unless content_type.present?
    allowed = AllowedMimeType.enabled_types
    return if allowed.empty?
    unless allowed.include?(content_type)
      errors.add(:content_type, I18n.t("activerecord.errors.models.shared_file.attributes.content_type.file_type_not_allowed", type: content_type))
    end
  end

  def file_attached
    errors.add(:file, I18n.t("activerecord.errors.models.shared_file.attributes.file.file_must_be_attached")) unless file.attached?
  end

  def within_user_quota
    return unless user && file_size.present?
    unless user.can_upload?(file_size)
      quota_display = ActionController::Base.helpers.number_to_human_size(user.disk_quota)
      errors.add(:base, I18n.t("activerecord.errors.models.shared_file.attributes.base.quota_exceeded", quota: quota_display))
    end
  end
end
