require "test_helper"

class TasteMatchCalculatorTest < ActiveSupport::TestCase
  test "calculates fiction score as average of rated fiction recs" do
    calc = TasteMatchCalculator.new(recommenders(:marco))
    calc.call
    # marco has loved (1.0) + liked (0.75) → avg 0.875
    assert_in_delta 0.875, recommenders(:marco).reload.fiction_match, 0.01
  end

  test "returns nil for category with no rated reads" do
    calc = TasteMatchCalculator.new(recommenders(:new_friend))
    calc.call
    assert_nil recommenders(:new_friend).reload.fiction_match
  end

  test "excludes skipped and pending recommendations" do
    # marco_skipped_with_rating has status=skipped and outcome_rating=loved
    # it must not inflate the fiction_match score
    calc = TasteMatchCalculator.new(recommenders(:marco))
    calc.call
    assert_in_delta 0.875, recommenders(:marco).reload.fiction_match, 0.01
  end

  test "returns nil for nonfiction when no nonfiction recs rated" do
    calc = TasteMatchCalculator.new(recommenders(:marco))
    calc.call
    assert_nil recommenders(:marco).reload.nonfiction_match
  end
end
