require "test_helper"

class WebauthnSessionsControllerTest < ActionDispatch::IntegrationTest
  test "returns five allow credentials regardless of account passkey count" do
    empty_user = create(:user, email_address: "empty@example.com")
    one_credential_user = create(:user, email_address: "one@example.com")
    one_credential_user.webauthn_credentials.create!(external_id: Base64.strict_encode64("one"), public_key: "key", sign_count: 0)
    many_credentials_user = create(:user, email_address: "many@example.com")
    6.times do |index|
      many_credentials_user.webauthn_credentials.create!(external_id: Base64.strict_encode64("credential-#{index}"), public_key: "key-#{index}", sign_count: 0)
    end

    [ "missing@example.com", empty_user.email_address, one_credential_user.email_address, many_credentials_user.email_address ].each do |email_address|
      get new_webauthn_session_path, params: { email_address: email_address }, as: :json
      assert_response :success
      assert_equal 5, JSON.parse(response.body).fetch("allowCredentials").length
    end
  end

  test "returns a generic error for an unknown credential" do
    post webauthn_session_path, params: { credential: {} }, as: :json

    assert_response :unprocessable_entity
    assert_equal I18n.t("flash.webauthn.sessions.create.invalid_credential"), JSON.parse(response.body).fetch("error")
  end
end
