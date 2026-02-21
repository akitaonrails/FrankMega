require "test_helper"

class SetupControllerTest < ActionDispatch::IntegrationTest
  test "shows setup form when no users exist" do
    get setup_path
    assert_response :success
  end

  test "creates admin user" do
    post setup_path, params: {
      user: {
        email_address: "admin@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
    assert_redirected_to root_path

    user = User.last
    assert_equal "admin", user.role
    assert_equal "admin@example.com", user.email_address
  end

  test "setup endpoint not accessible when users exist" do
    create(:user)
    get "/setup"
    # Catch-all redirects to login, or returns 404
    assert_includes [ 302, 404 ], response.status
  end
end
