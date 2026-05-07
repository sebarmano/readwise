require "test_helper"

class FriendshipsControllerTest < ActionDispatch::IntegrationTest
  # --- authentication ---

  test "index redirects to sign in when unauthenticated" do
    get friendships_path
    assert_redirected_to new_session_path
  end

  test "create redirects to sign in when unauthenticated" do
    post friendships_path, params: {friendship: {email: users(:two).email_address}}
    assert_redirected_to new_session_path
  end

  # --- index ---

  test "index shows accepted friends" do
    sign_in_as users(:one)
    get friendships_path
    assert_response :success
    assert_includes response.body, users(:two).email_address
  end

  test "index shows pending received invites" do
    sign_in_as users(:three)
    get friendships_path
    assert_response :success
    assert_includes response.body, users(:one).email_address
  end

  test "index does not show other users data" do
    sign_in_as users(:one)
    get friendships_path
    assert_not_includes response.body, users(:three).email_address
  end

  # --- create (invite) ---

  test "create sends invite and redirects" do
    sign_in_as users(:two)
    assert_difference -> { Friendship.count }, 1 do
      post friendships_path, params: {friendship: {email: users(:three).email_address}}
    end
    assert_redirected_to friendships_path
  end

  test "create is silent no-op for unknown email" do
    sign_in_as users(:one)
    assert_no_difference -> { Friendship.count } do
      post friendships_path, params: {friendship: {email: "nobody@example.com"}}
    end
    assert_redirected_to friendships_path
  end

  # --- update (accept) ---

  test "update accepts a pending friendship" do
    sign_in_as users(:three)
    patch friendship_path(friendships(:one_three_pending))
    assert friendships(:one_three_pending).reload.accepted?
    assert_redirected_to friendships_path
  end

  test "update does not allow sender to accept their own invite" do
    sign_in_as users(:one)
    patch friendship_path(friendships(:one_three_pending))
    assert friendships(:one_three_pending).reload.pending?
  end

  test "update returns 404 for unrelated friendship" do
    sign_in_as users(:two)
    patch friendship_path(friendships(:one_three_pending))
    assert_response :not_found
  end

  # --- destroy (remove / decline) ---

  test "destroy removes an accepted friendship" do
    sign_in_as users(:one)
    assert_difference -> { Friendship.count }, -1 do
      delete friendship_path(friendships(:one_two))
    end
    assert_redirected_to friendships_path
  end

  test "destroy allows recipient to decline pending invite" do
    sign_in_as users(:three)
    assert_difference -> { Friendship.count }, -1 do
      delete friendship_path(friendships(:one_three_pending))
    end
  end

  test "destroy returns 404 for unrelated friendship" do
    sign_in_as users(:two)
    delete friendship_path(friendships(:one_three_pending))
    assert_response :not_found
  end

  # --- Turbo Stream ---

  test "update returns turbo stream when requested" do
    sign_in_as users(:three)
    patch friendship_path(friendships(:one_three_pending)),
      headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "destroy returns turbo stream when requested" do
    sign_in_as users(:one)
    delete friendship_path(friendships(:one_two)),
      headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end
end
