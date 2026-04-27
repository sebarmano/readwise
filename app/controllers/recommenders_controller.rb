class RecommendersController < ApplicationController
  def index
    @recommenders = Current.user.recommenders.friend.includes(:recommendations).order(:name)
  end
end
