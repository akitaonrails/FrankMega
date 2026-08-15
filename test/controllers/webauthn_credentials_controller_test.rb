require "test_helper"

class WebauthnCredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Current.reset
    @user = create(:user, email_address: "credential@example.com", password: "password123!safe")
    @credential = @user.webauthn_credentials.create!(external_id: Base64.strict_encode64("credential"), public_key: "key", sign_count: 0)
    post session_path, params: { email_address: @user.email_address, password: "password123!safe" }, env: { "REMOTE_ADDR" => "10.0.0.250" }
  end

  test "requires the current password to remove a passkey" do
    assert_no_difference "WebauthnCredential.count" do
      delete webauthn_credential_path(@credential)
    end
    assert_redirected_to profile_path

    assert_no_difference "WebauthnCredential.count" do
      delete webauthn_credential_path(@credential), params: { current_password: "incorrect" }
    end
    assert_redirected_to profile_path

    assert_difference "WebauthnCredential.count", -1 do
      delete webauthn_credential_path(@credential), params: { current_password: "password123!safe" }
    end
    assert_redirected_to profile_path
  end
end
