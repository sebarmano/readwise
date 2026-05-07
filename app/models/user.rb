class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :books, dependent: :destroy
  has_many :recommenders, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :preferences, class_name: "UserPreference", dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
end
