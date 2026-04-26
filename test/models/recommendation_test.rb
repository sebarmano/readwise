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
end
