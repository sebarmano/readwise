class TasteMatchCalculator
  SCORES = {"meh" => 0.25, "liked" => 0.75, "loved" => 1.0}.freeze

  def initialize(recommender)
    @recommender = recommender
  end

  def call
    @recommender.update!(
      fiction_match: score_for("fiction"),
      nonfiction_match: score_for("non-fiction")
    )
  end

  private

  def score_for(book_type)
    rated = @recommender.recommendations
      .read
      .where(book_type: book_type)
      .where.not(outcome_rating: nil)

    return nil if rated.empty?

    rated.sum { |r| SCORES[r.outcome_rating] } / rated.size
  end
end
