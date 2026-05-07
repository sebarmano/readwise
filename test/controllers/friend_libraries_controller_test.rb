require "test_helper"

class FriendLibrariesControllerTest < ActionDispatch::IntegrationTest
  # --- authentication ---

  test "redirects to sign in when unauthenticated" do
    get friend_library_path(users(:two))
    assert_redirected_to new_session_path
  end

  # --- authorization ---

  test "returns 403 when users are not friends" do
    sign_in_as users(:two)
    get friend_library_path(users(:three))
    assert_response :forbidden
  end

  # --- full visibility ---

  test "shows all books when friend has full visibility" do
    users(:two).update!(library_visibility: :full)
    sign_in_as users(:one)
    get friend_library_path(users(:two))
    assert_response :success
    assert_includes response.body, books(:other_users_book).title
  end

  # --- current_book visibility ---

  test "shows only currently reading when friend has current_book visibility" do
    users(:two).update!(library_visibility: :current_book)
    sign_in_as users(:one)
    get friend_library_path(users(:two))
    assert_response :success
    assert_not_includes response.body, books(:other_users_book).title
  end

  # --- activity_only visibility ---

  test "shows activity only message when friend has activity_only visibility" do
    users(:two).update!(library_visibility: :activity_only)
    sign_in_as users(:one)
    get friend_library_path(users(:two))
    assert_response :success
    assert_includes response.body, "is reading something"
  end

  # --- hidden visibility ---

  test "shows empty state when friend has hidden visibility" do
    users(:two).update!(library_visibility: :hidden)
    sign_in_as users(:one)
    get friend_library_path(users(:two))
    assert_response :success
    assert_includes response.body, "sharing their library"
  end
end
