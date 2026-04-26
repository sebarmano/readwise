class RecommendationsController < ApplicationController
  def index
    @recommendations = Current.user.recommendations.includes(:recommender).by_queue_order
  end

  def new
    @recommendation = Recommendation.new
    @recommender_names = Current.user.recommenders.friend.pluck(:name)
  end

  def create
    recommended_by = params.dig(:recommendation, :recommended_by).to_s.strip

    if recommended_by.blank?
      @recommendation = Current.user.recommendations.build(recommendation_create_params)
      @recommendation.errors.add(:base, "Friend name can't be blank")
      @recommender_names = Current.user.recommenders.friend.pluck(:name)
      return render :new, status: :unprocessable_entity
    end

    recommender = Current.user.recommenders.find_or_create_by!(
      name: recommended_by,
      recommender_type: :friend
    )
    @recommendation = Current.user.recommendations.build(
      recommendation_create_params.merge(recommender: recommender, status: :pending)
    )

    if @recommendation.save
      redirect_to recommendations_path, notice: "Added to your reading queue."
    else
      @recommender_names = Current.user.recommenders.friend.pluck(:name)
      render :new, status: :unprocessable_entity
    end
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

  def recommendation_create_params
    params.expect(recommendation: [:book_title, :book_author, :reason])
  end
end
