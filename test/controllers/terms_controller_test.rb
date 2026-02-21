require "test_helper"

class TermsControllerTest < ActionDispatch::IntegrationTest
  test "shows terms page without authentication" do
    get terms_path
    assert_response :success
  end

  test "shows terms page when authenticated" do
    user = create(:user)
    post session_path, params: { email_address: user.email_address, password: "password123!safe" }

    get terms_path
    assert_response :success
  end
end
