class RecommendersController < ApplicationController
  def index
    @recommenders = Current.user.recommenders
  end
end
