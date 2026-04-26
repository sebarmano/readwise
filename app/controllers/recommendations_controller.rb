class RecommendationsController < ApplicationController
  def index
    @recommendations = Current.user.recommendations.includes(:recommender).by_queue_order
  end

  def show
    @recommendation = Current.user.recommendations.find(params[:id])
  end

  def update
    @recommendation = Current.user.recommendations.find(params[:id])
    @recommendation.update!(recommendation_params)
    TasteMatchCalculator.new(@recommendation.recommender).call if @recommendation.saved_change_to_outcome_rating?
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to recommendations_path }
    end
  rescue ArgumentError
    head :unprocessable_entity
  end

  def destroy
    Current.user.recommendations.find(params[:id]).destroy
    redirect_to recommendations_path
  end

  private

  def recommendation_params
    params.expect(recommendation: [:status, :outcome_rating])
  end
end
