require "test_helper"

class FriendshipServiceTest < ActiveSupport::TestCase
  # --- invite ---

  test "invite creates a pending friendship" do
    result = nil
    assert_difference -> { Friendship.count }, 1 do
      result = FriendshipService.invite(from: users(:two), email: users(:three).email_address)
    end
    assert result.pending?
  end

  test "invite is a silent no-op when email is not found" do
    assert_no_difference -> { Friendship.count } do
      FriendshipService.invite(from: users(:one), email: "nobody@example.com")
    end
  end

  test "invite cannot send to yourself" do
    assert_no_difference -> { Friendship.count } do
      FriendshipService.invite(from: users(:one), email: users(:one).email_address)
    end
  end

  test "invite is a no-op when friendship already exists" do
    assert_no_difference -> { Friendship.count } do
      FriendshipService.invite(from: users(:one), email: users(:two).email_address)
    end
  end

  test "invite returns nil on silent no-op" do
    result = FriendshipService.invite(from: users(:one), email: "nobody@example.com")
    assert_nil result
  end

  # --- accept ---

  test "accept transitions a pending friendship to accepted" do
    friendship = friendships(:one_three_pending)
    FriendshipService.accept(friendship: friendship, user: users(:three))
    assert friendship.reload.accepted?
  end

  test "accept is idempotent when already accepted" do
    friendship = friendships(:one_two)
    assert_nothing_raised do
      FriendshipService.accept(friendship: friendship, user: users(:two))
    end
    assert friendship.reload.accepted?
  end

  test "accept does nothing when called by the sender" do
    friendship = friendships(:one_three_pending)
    FriendshipService.accept(friendship: friendship, user: users(:one))
    assert friendship.reload.pending?
  end

  # --- remove ---

  test "remove destroys a pending friendship" do
    assert_difference -> { Friendship.count }, -1 do
      FriendshipService.remove(friendship: friendships(:one_three_pending), user: users(:one))
    end
  end

  test "remove destroys an accepted friendship" do
    assert_difference -> { Friendship.count }, -1 do
      FriendshipService.remove(friendship: friendships(:one_two), user: users(:two))
    end
  end

  test "remove works for the recipient too" do
    assert_difference -> { Friendship.count }, -1 do
      FriendshipService.remove(friendship: friendships(:one_three_pending), user: users(:three))
    end
  end
end
