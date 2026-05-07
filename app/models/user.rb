class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :books, dependent: :destroy
  has_many :recommenders, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :preferences, class_name: "UserPreference", dependent: :destroy
  has_many :sent_friendships, class_name: "Friendship", foreign_key: :user_id, dependent: :destroy
  has_many :received_friendships, class_name: "Friendship", foreign_key: :friend_id, dependent: :destroy
  has_many :notifications, dependent: :destroy

  enum :library_visibility, {full: 0, current_book: 1, activity_only: 2, hidden: 3}

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true

  def friends
    friend_ids = sent_friendships.accepted.pluck(:friend_id) +
      received_friendships.accepted.pluck(:user_id)
    User.where(id: friend_ids)
  end

  def pending_sent
    User.where(id: sent_friendships.pending.pluck(:friend_id))
  end

  def pending_received
    User.where(id: received_friendships.pending.pluck(:user_id))
  end
end
