require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign in with valid credentials" do
    user = create_user

    sign_in_as user

    assert_current_path root_path
    assert_text "ReadWise"
  end

  test "user sees error with invalid credentials" do
    visit new_session_path
    fill_in "Email address", with: "wrong@example.com"
    fill_in "Password", with: "wrong"
    click_on "Sign in"

    assert_text "Try another email address or password"
  end

  test "unauthenticated user is redirected to sign in" do
    visit root_path

    assert_current_path new_session_path
  end
end
