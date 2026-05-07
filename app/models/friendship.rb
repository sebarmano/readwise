class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"

  enum :status, {pending: 0, accepted: 1}

  validates :user, :friend, :status, presence: true
  validates :friend_id, uniqueness: {scope: :user_id}
  validate :not_self_friendship

  scope :accepted, -> { where(status: :accepted) }
  scope :pending, -> { where(status: :pending) }

  private

  def not_self_friendship
    errors.add(:friend_id, "can't be yourself") if user_id == friend_id
  end
end
