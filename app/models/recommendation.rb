class Recommendation < ApplicationRecord
  belongs_to :user
  belongs_to :recommender

  enum :status, {pending: 0, reading: 1, read: 2, skipped: 3}

  validates :book_title, :book_author, :status, presence: true

  scope :active, -> { where(status: [:pending, :reading]) }
  scope :recent, -> { order(created_at: :desc) }
end
