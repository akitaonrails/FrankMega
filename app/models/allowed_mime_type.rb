class AllowedMimeType < ApplicationRecord
  validates :mime_type, presence: true, uniqueness: true

  scope :enabled, -> { where(enabled: true) }

  def self.enabled_types
    enabled.pluck(:mime_type)
  end

  def self.seed_defaults!
    defaults = {
      "application/pdf" => "PDF Document",
      "application/zip" => "ZIP Archive",
      "application/x-7z-compressed" => "7-Zip Archive",
      "application/gzip" => "GZip Archive",
      "application/x-tar" => "TAR Archive",
      "image/jpeg" => "JPEG Image",
      "image/png" => "PNG Image",
      "image/gif" => "GIF Image",
      "image/webp" => "WebP Image",
      "image/svg+xml" => "SVG Image",
      "video/mp4" => "MP4 Video",
      "video/webm" => "WebM Video",
      "audio/mpeg" => "MP3 Audio",
      "audio/ogg" => "OGG Audio",
      "text/plain" => "Plain Text",
      "text/csv" => "CSV File",
      "application/json" => "JSON File",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "Word Document",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => "Excel Spreadsheet",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "PowerPoint Presentation"
    }

    defaults.each do |mime, desc|
      find_or_create_by!(mime_type: mime) { |m| m.description = desc }
    end
  end
end
