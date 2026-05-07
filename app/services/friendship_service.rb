class FriendshipService
  def self.invite(from:, email:)
    friend = User.find_by(email_address: email)
    return nil unless friend
    return nil if friend == from
    return nil if existing_friendship?(from, friend)

    friendship = Friendship.create!(user: from, friend: friend, status: :pending)
    friend.notifications.create!(notifiable: friendship)
    friendship
  end

  def self.accept(friendship:, user:)
    return unless friendship.friend == user
    friendship.update!(status: :accepted)
    friendship.notifications.unread.each(&:read!)
  end

  def self.remove(friendship:, user:)
    return unless friendship.user == user || friendship.friend == user
    friendship.notifications.unread.each(&:read!)
    friendship.destroy!
  end

  def self.existing_friendship?(user_a, user_b)
    Friendship.where(user: user_a, friend: user_b)
      .or(Friendship.where(user: user_b, friend: user_a))
      .exists?
  end
  private_class_method :existing_friendship?
end
