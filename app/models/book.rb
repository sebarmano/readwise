class Book < ApplicationRecord
  belongs_to :user
  has_one :book_profile

  enum :rating, {meh: 1, liked: 2, loved: 3}

  validates :title, :author, :rating, presence: true
  validates :year, numericality: {only_integer: true, allow_nil: true}

  scope :by_rating, ->(r) { where(rating: r) }
  scope :by_genre, ->(g) { where(genre: g) }
  scope :recent, -> { order(read_at: :desc, created_at: :desc) }
  scope :search, ->(q) { where("title LIKE ? OR author LIKE ? OR notes LIKE ?", "%#{q}%", "%#{q}%", "%#{q}%") }

  def profiled?
    book_profile.present?
  end
end
