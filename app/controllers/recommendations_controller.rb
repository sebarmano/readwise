class RecommendationsController < ApplicationController
  def index
    @recommendations = Current.user.recommendations.recent
  end

  def show
    @recommendation = Current.user.recommendations.find(params[:id])
  end

  def update
    @recommendation = Current.user.recommendations.find(params[:id])
    @recommendation.update!(recommendation_params)
    redirect_to recommendations_path
  end

  def destroy
    Current.user.recommendations.find(params[:id]).destroy
    redirect_to recommendations_path
  end

  private

  def recommendation_params
    params.expect(recommendation: [:status])
  end
end
