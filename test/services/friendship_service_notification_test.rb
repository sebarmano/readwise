require "test_helper"

class FriendshipServiceNotificationTest < ActiveSupport::TestCase
  test "invite creates a notification for the recipient" do
    assert_difference -> { users(:three).notifications.count }, 1 do
      FriendshipService.invite(from: users(:two), email: users(:three).email_address)
    end
  end

  test "invite notification is unread" do
    FriendshipService.invite(from: users(:two), email: users(:three).email_address)
    assert users(:three).notifications.last.unread?
  end

  test "accept marks the friendship notification as read" do
    friendship = friendships(:one_three_pending)
    FriendshipService.accept(friendship: friendship, user: users(:three))
    assert_not users(:three).notifications.find_by(notifiable: friendship)&.unread?
  end

  test "remove marks the friendship notification as read" do
    friendship = friendships(:one_three_pending)
    FriendshipService.remove(friendship: friendship, user: users(:three))
    assert_equal 0, users(:three).notifications.unread.count
  end
end
