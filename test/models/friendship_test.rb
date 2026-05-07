require "test_helper"

class FriendshipTest < ActiveSupport::TestCase
  # Validations
  test "valid with user, friend, and status" do
    f = Friendship.new(user: users(:two), friend: users(:three), status: :pending)
    assert f.valid?
  end

  test "invalid without user" do
    f = Friendship.new(friend: users(:two), status: :pending)
    assert_not f.valid?
  end

  test "invalid without friend" do
    f = Friendship.new(user: users(:one), status: :pending)
    assert_not f.valid?
  end

  test "cannot friend yourself" do
    f = Friendship.new(user: users(:one), friend: users(:one), status: :pending)
    assert_not f.valid?
    assert_includes f.errors[:friend_id], "can't be yourself"
  end

  test "cannot duplicate an existing friendship" do
    # friendships(:one_two) already exists
    f = Friendship.new(user: users(:one), friend: users(:two), status: :pending)
    assert_not f.valid?
  end

  # Enum
  test "status defaults to pending" do
    f = Friendship.new(user: users(:one), friend: users(:three), status: :pending)
    assert f.pending?
  end

  test "can transition to accepted" do
    f = friendships(:one_two)
    assert f.accepted?
  end

  # Scopes
  test "accepted scope returns only accepted friendships" do
    assert_includes Friendship.accepted, friendships(:one_two)
    assert_not_includes Friendship.accepted, friendships(:one_three_pending)
  end

  test "pending scope returns only pending friendships" do
    assert_includes Friendship.pending, friendships(:one_three_pending)
    assert_not_includes Friendship.pending, friendships(:one_two)
  end
end
