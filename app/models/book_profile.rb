class BookProfile < ApplicationRecord
  belongs_to :book
  validates :book, uniqueness: true
end
