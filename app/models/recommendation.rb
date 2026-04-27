class Recommendation < ApplicationRecord
  belongs_to :user
  belongs_to :recommender

  enum :status, {pending: 0, reading: 1, read: 2, skipped: 3}
  enum :outcome_rating, {meh: 1, liked: 2, loved: 3}

  validates :book_title, :book_author, :status, presence: true

  before_save -> { self.read_at ||= Date.current }, if: :read?

  scope :active, -> { where(status: [:pending, :reading]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_queue_order, -> {
    order(Arel.sql("CASE status WHEN 1 THEN 0 WHEN 0 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 3 END"), created_at: :desc)
  }

  def mark_as_read!(outcome_rating:)
    update!(status: :read, outcome_rating:, read_at: Date.current)
    TasteMatchCalculator.new(recommender).call
  end

  def complete!(outcome_rating:)
    update!(status: :read, outcome_rating:, read_at: Date.current)
    TasteMatchCalculator.new(recommender).call if recommender.friend?
  end
end
