class Recommender < ApplicationRecord
  belongs_to :user
  has_many :recommendations, dependent: :destroy

  enum :recommender_type, {friend: 0, claude: 1}

  validates :name, :recommender_type, presence: true
  validates :email_address, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
end
