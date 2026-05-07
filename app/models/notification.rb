class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  validates :user, presence: true

  scope :unread, -> { where(read_at: nil) }

  def read!
    update!(read_at: Time.current)
  end

  def unread?
    read_at.nil?
  end
end
