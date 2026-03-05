class AllowedMimeType < ApplicationRecord
  normalizes :mime_type, with: ->(val) { val.strip }

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
      "application/x-xz" => "XZ Archive",
      "application/x-bzip2" => "BZip2 Archive",
      "application/x-rar-compressed" => "RAR Archive",
      "application/x-apple-diskimage" => "DMG Disk Image",
      "application/zlib" => "Zlib Compressed Data (DMG/other)",
      "application/x-debian-package" => "DEB Package",
      "application/x-rpm" => "RPM Package",
      "application/x-executable" => "Linux Executable",
      "application/x-ms-installer" => "Windows Installer (MSI)",
      "application/x-dosexec" => "Windows Executable (EXE/DLL)",
      "application/x-iso9660-image" => "ISO Disk Image",
      "application/octet-stream" => "Binary File (AppImage/pkg/other)",
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
      "application/vnd.android.package-archive" => "Android APK",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "PowerPoint Presentation"
    }

    defaults.each do |mime, desc|
      find_or_create_by!(mime_type: mime) { |m| m.description = desc }
    end
  end
end
