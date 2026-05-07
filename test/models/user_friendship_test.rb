require "test_helper"

class UserFriendshipTest < ActiveSupport::TestCase
  # library_visibility
  test "library_visibility defaults to full" do
    user = User.new(email_address: "vis@example.com", password: "password")
    user.save!
    assert user.full?
  end

  test "library_visibility enum has all expected values" do
    assert_equal %w[full current_book activity_only hidden], User.library_visibilities.keys
  end

  # associations
  test "has many sent_friendships" do
    assert_includes users(:one).sent_friendships, friendships(:one_two)
  end

  test "has many received_friendships" do
    assert_includes users(:two).received_friendships, friendships(:one_two)
  end

  # friends scope (bidirectional)
  test "friends includes accepted friendship where user is sender" do
    assert_includes users(:one).friends, users(:two)
  end

  test "friends includes accepted friendship where user is receiver" do
    assert_includes users(:two).friends, users(:one)
  end

  test "friends does not include pending friendships" do
    assert_not_includes users(:one).friends, users(:three)
  end

  # pending_received / pending_sent
  test "pending_received returns users who sent a pending invite to this user" do
    assert_includes users(:three).pending_received, users(:one)
  end

  test "pending_sent returns users this user has invited but not yet accepted" do
    assert_includes users(:one).pending_sent, users(:three)
  end

  test "pending_received does not include accepted friends" do
    assert_not_includes users(:two).pending_received, users(:one)
  end
end
