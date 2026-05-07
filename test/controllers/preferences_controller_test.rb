require "test_helper"

class PreferencesControllerTest < ActionDispatch::IntegrationTest
  # --- authentication ---

  test "index redirects to sign in when unauthenticated" do
    get preferences_path
    assert_redirected_to new_session_path
  end

  test "destroy redirects to sign in when unauthenticated" do
    delete preference_path(user_preferences(:slow_burn))
    assert_redirected_to new_session_path
  end

  # --- index ---

  test "index shows only the current user's preferences" do
    sign_in_as users(:one)
    get preferences_path
    assert_response :success
    assert_includes response.body, user_preferences(:slow_burn).signal
    assert_not_includes response.body, user_preferences(:user_two_pref).signal
  end

  test "index shows empty state when user has no preferences" do
    user = User.create!(email_address: "empty_prefs@example.com", password: "password")
    sign_in_as user
    get preferences_path
    assert_response :success
    assert_includes response.body, "No taste signals yet"
  end

  # --- destroy ---

  test "destroy deletes the preference and redirects" do
    sign_in_as users(:one)
    assert_difference -> { UserPreference.count }, -1 do
      delete preference_path(user_preferences(:slow_burn))
    end
    assert_redirected_to preferences_path
  end

  test "destroy returns turbo stream that removes the card" do
    sign_in_as users(:one)
    delete preference_path(user_preferences(:slow_burn)),
      headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "remove"
    assert_includes response.body, "preference_#{user_preferences(:slow_burn).id}"
  end

  test "destroy returns 404 for another user's preference" do
    sign_in_as users(:one)
    delete preference_path(user_preferences(:user_two_pref))
    assert_response :not_found
  end
end
