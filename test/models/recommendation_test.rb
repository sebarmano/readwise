require "test_helper"

class RecommendationTest < ActiveSupport::TestCase
  test "by_queue_order puts reading before pending" do
    recs = Recommendation.where(user: users(:one)).by_queue_order
    reading_idx = recs.index { |r| r.reading? }
    pending_idx = recs.index { |r| r.pending? }
    assert reading_idx < pending_idx
  end

  test "by_queue_order puts pending before read" do
    recs = Recommendation.where(user: users(:one)).by_queue_order
    pending_idx = recs.index { |r| r.pending? }
    read_idx = recs.index { |r| r.read? }
    assert pending_idx < read_idx
  end

  test "by_queue_order puts read before skipped" do
    recs = Recommendation.where(user: users(:one)).by_queue_order
    read_idx = recs.index { |r| r.read? }
    skipped_idx = recs.index { |r| r.skipped? }
    assert read_idx < skipped_idx
  end

  test "complete! sets status to read with outcome rating" do
    rec = recommendations(:marco_pending_fiction)
    rec.complete!(outcome_rating: "loved")
    rec.reload
    assert rec.read?
    assert_equal "loved", rec.outcome_rating
  end

  test "complete! recalculates taste match for friend rec" do
    rec = recommendations(:marco_pending_fiction)
    rec.complete!(outcome_rating: "loved")
    assert_not_nil recommenders(:marco).reload.fiction_match
  end

  test "complete! does not recalculate taste match for claude rec" do
    rec = recommendations(:claude_pending)
    rec.complete!(outcome_rating: "liked")
    assert_equal 0.5, recommenders(:one).reload.fiction_match
  end
end
