require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "valid with user and notifiable" do
    n = Notification.new(user: users(:two), notifiable: friendships(:one_two))
    assert n.valid?
  end

  test "invalid without user" do
    n = Notification.new(notifiable: friendships(:one_two))
    assert_not n.valid?
  end

  test "unread scope returns notifications with nil read_at" do
    assert_includes Notification.unread, notifications(:pending_invite)
  end

  test "unread scope excludes read notifications" do
    assert_not_includes Notification.unread, notifications(:read_invite)
  end

  test "read! marks notification as read" do
    notifications(:pending_invite).read!
    assert_not_nil notifications(:pending_invite).reload.read_at
  end

  test "unread? returns true when not yet read" do
    assert notifications(:pending_invite).unread?
  end

  test "unread? returns false when read" do
    assert_not notifications(:read_invite).unread?
  end
end
