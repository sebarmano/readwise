class UserPreference < ApplicationRecord
  belongs_to :user

  validates :signal, presence: true
  validates :source, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_context, -> { recent.limit(15) }
end
