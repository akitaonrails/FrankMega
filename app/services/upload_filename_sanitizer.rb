class UploadFilenameSanitizer
  KNOWN_EXTENSIONS = %w[
    jpg jpeg png gif webp bmp tiff tif svg ico
    pdf doc docx xls xlsx ppt pptx odt ods odp rtf
    zip gz bz2 xz tar rar 7z
    mp3 mp4 m4a m4v avi mov mkv wmv flv webm wav flac ogg aac
    txt csv json xml yaml yml html htm css js rb py sh md
  ].freeze

  def self.call(name, content_type = nil)
    new(name, content_type).call
  end

  def initialize(name, content_type = nil)
    @name = name
    @content_type = content_type
  end

  def call
    sanitized = File.basename(@name.to_s)
    sanitized = sanitized.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    sanitized = sanitized.gsub(/[\x00-\x1f\x7f\/\\:*?"<>|]/, "")
    sanitized = sanitized.sub(/\A\.+/, "")
    sanitized = sanitized.gsub(/\s+/, " ").strip

    base_without_ext = sanitized.sub(/\.[^.]*\z/, "")
    if base_without_ext.match?(/\A(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])\z/i)
      sanitized = "_#{sanitized}"
    end

    sanitized = strip_extension_junk(sanitized)
    sanitized = truncate_filename(sanitized, 255)
    sanitized.presence || "unnamed_file"
  end

  private

  def strip_extension_junk(name)
    ext_pattern = KNOWN_EXTENSIONS.join("|")
    match = name.match(/\A(.+?)\.(#{ext_pattern})[_,+]/i)
    return name unless match

    clean_name = "#{match[1]}.#{match[2]}"
    correct_ext = MiniMime.lookup_by_content_type(@content_type)&.extension if @content_type

    if correct_ext && !clean_name.downcase.end_with?(".#{correct_ext.downcase}")
      clean_name = "#{match[1]}.#{correct_ext}"
    end

    clean_name
  end

  def truncate_filename(name, max_bytes)
    return name if name.bytesize <= max_bytes

    ext = File.extname(name)
    base = File.basename(name, ext)
    max_base = max_bytes - ext.bytesize
    return ext.byteslice(0, max_bytes) if max_base <= 0

    base = base.chop while base.bytesize > max_base
    "#{base}#{ext}"
  end
end
