require "test_helper"

class UploadFilenameSanitizerTest < ActiveSupport::TestCase
  test "truncates a multibyte extension without invalid UTF-8" do
    filename = "file.#{'界' * 100}"

    sanitized = UploadFilenameSanitizer.call(filename)

    assert sanitized.valid_encoding?
    assert_operator sanitized.bytesize, :<=, 255
  end

  test "removes directional controls, isolates, BOM, and zero-width characters" do
    filename = "safe\u202Ename\u2066file\uFEFFzero\u200Bwidth\u200Cjoin\u200D.txt"

    assert_equal "safenamefilezerowidthjoin.txt", UploadFilenameSanitizer.call(filename)
  end
end
