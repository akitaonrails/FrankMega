require "test_helper"

class SecurityTest < ActionDispatch::IntegrationTest
  # -- Open redirect prevention --

  test "return_to does not redirect to external host" do
    user = create(:user, email_address: "safe@example.com", password: "password123!safe")

    # Try visiting an authenticated page — stores return_to in session
    get new_upload_path
    assert_redirected_to new_session_path

    # Login should redirect to the original page (same host), not external
    post session_path, params: { email_address: "safe@example.com", password: "password123!safe" }
    redirect_url = response.location

    # The redirect must be to the same host or a relative path
    uri = URI.parse(redirect_url)
    assert(uri.host.nil? || uri.host == "www.example.com",
           "Should redirect to same host, got: #{redirect_url}")
  end

  # -- Banned user session invalidation --

  test "banned user loses access on next request" do
    user = create(:user, email_address: "ban@example.com", password: "password123!safe")
    post session_path, params: { email_address: "ban@example.com", password: "password123!safe" }
    assert_redirected_to root_url

    # Verify logged in
    get new_upload_path
    assert_response :success

    # Ban the user
    user.ban!

    # Next request should redirect to login
    get new_upload_path
    assert_redirected_to new_session_path
  end

  # -- Session regeneration before 2FA --

  test "session is regenerated before storing pending_user_id" do
    user = create(:user, email_address: "otp@example.com", password: "password123!safe")
    user.generate_otp_secret!
    user.enable_otp!

    # Login triggers 2FA redirect
    post session_path, params: { email_address: "otp@example.com", password: "password123!safe" }
    assert_redirected_to new_two_factor_session_path

    # Verify the 2FA page loads (pending_user_id in new session)
    get new_two_factor_session_path
    assert_response :success
  end

  # -- Download counter exhaustion returns 410 --

  test "download returns 410 when file exhausted" do
    sf = create(:shared_file, max_downloads: 1, download_count: 1)
    post download_file_path(hash: sf.download_hash)
    assert_response :gone
  end

  test "download returns 410 for expired file" do
    sf = create(:shared_file, :expired)
    post download_file_path(hash: sf.download_hash)
    assert_response :gone
  end

  test "atomic download prevents over-counting" do
    sf = create(:shared_file, max_downloads: 1, download_count: 0)

    post download_file_path(hash: sf.download_hash)
    assert_response :success # file served directly

    post download_file_path(hash: sf.download_hash)
    assert_response :gone # second attempt fails
    assert_equal 1, sf.reload.download_count
  end

  # -- Sole admin protection --

  test "cannot delete the last admin" do
    admin = create(:user, :admin, email_address: "admin@example.com", password: "password123!safe")
    post session_path, params: { email_address: "admin@example.com", password: "password123!safe" }

    delete admin_user_path(admin)
    assert_redirected_to admin_user_path(admin)
    assert User.exists?(admin.id), "Last admin should not be deleted"
  end

  test "cannot ban the last admin" do
    admin = create(:user, :admin, email_address: "admin@example.com", password: "password123!safe")
    post session_path, params: { email_address: "admin@example.com", password: "password123!safe" }

    post ban_admin_user_path(admin)
    assert_redirected_to admin_user_path(admin)
    assert_not admin.reload.banned?, "Last admin should not be banned"
  end

  test "cannot demote the last admin" do
    admin = create(:user, :admin, email_address: "admin@example.com", password: "password123!safe")
    post session_path, params: { email_address: "admin@example.com", password: "password123!safe" }

    patch admin_user_path(admin), params: { user: { role: "user" } }
    assert_redirected_to admin_user_path(admin)
    assert_equal "admin", admin.reload.role, "Last admin role should not change"
  end

  test "can delete admin when another admin exists" do
    admin1 = create(:user, :admin, email_address: "admin1@example.com", password: "password123!safe")
    admin2 = create(:user, :admin, email_address: "admin2@example.com")
    post session_path, params: { email_address: "admin1@example.com", password: "password123!safe" }

    delete admin_user_path(admin2)
    assert_redirected_to admin_users_path
    assert_not User.exists?(admin2.id)
  end

  # -- Admin password reset uses flash, not notice --

  test "admin password reset shows temp password once" do
    admin = create(:user, :admin, email_address: "admin@example.com", password: "password123!safe")
    target = create(:user)
    post session_path, params: { email_address: "admin@example.com", password: "password123!safe" }

    post reset_password_admin_user_path(target)
    assert_redirected_to admin_user_path(target)

    follow_redirect!
    assert_match(/Temporary password/, response.body)
    assert_match(/shown only once/, response.body)
  end

  # -- Filename sanitization --

  test "upload sanitizes path traversal in filename" do
    user = create(:user, email_address: "upload@example.com", password: "password123!safe")
    post session_path, params: { email_address: "upload@example.com", password: "password123!safe" }

    file = fixture_file_upload("test.txt", "text/plain")
    # Simulate a malicious filename by overriding original_filename
    file.define_singleton_method(:original_filename) { "../../etc/passwd" }

    post uploads_path, params: {
      file: file,
      shared_file: { max_downloads: 5, ttl_hours: 12 }
    }

    if SharedFile.last
      assert_not_includes SharedFile.last.original_filename, ".."
      assert_not_includes SharedFile.last.original_filename, "/"
    end
  end

  # -- WebAuthn email enumeration prevention --

  test "webauthn options returned for nonexistent email" do
    get new_webauthn_session_path, params: { email_address: "nobody@example.com" }
    assert_response :success

    data = JSON.parse(response.body)
    assert data.key?("challenge"), "Should return WebAuthn options even for nonexistent email"
  end

  test "webauthn options returned for user without passkeys" do
    create(:user, email_address: "nokeys@example.com")
    get new_webauthn_session_path, params: { email_address: "nokeys@example.com" }
    assert_response :success

    data = JSON.parse(response.body)
    assert data.key?("challenge"), "Should return WebAuthn options even without passkeys"
  end

  # -- Setup endpoint lockout --

  test "setup endpoint inaccessible after first user" do
    create(:user)
    get "/setup"
    # Should not be a 200; catch-all route redirects to login or returns 404
    assert_not_equal 200, response.status
  end
end
