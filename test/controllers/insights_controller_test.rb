require "test_helper"

class InsightsControllerTest < ActionDispatch::IntegrationTest
  test "redirects when not signed in" do
    get insights_path
    assert_redirected_to new_session_path
  end

  test "index succeeds for signed-in user" do
    sign_in_as users(:one)
    get insights_path
    assert_response :success
  end

  test "index only counts current user books" do
    sign_in_as users(:one)
    get insights_path
    assert_response :success
    # user :two has one book; user :one has 10 — verify isolation via response
    assert_match users(:one).books.count.to_s, response.body
  end
end
