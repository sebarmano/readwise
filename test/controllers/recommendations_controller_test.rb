require "test_helper"

class RecommendationsControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when unauthenticated" do
    patch recommendation_path(recommendations(:marco_pending)),
      params: {recommendation: {status: "reading"}}
    assert_redirected_to new_session_path
  end

  test "updates status to reading" do
    sign_in_as users(:one)
    patch recommendation_path(recommendations(:marco_pending)),
      params: {recommendation: {status: "reading"}}
    assert_equal "reading", recommendations(:marco_pending).reload.status
  end

  test "updates outcome rating" do
    sign_in_as users(:one)
    rec = recommendations(:one) # status: reading
    patch recommendation_path(rec), params: {recommendation: {status: "read"}}
    patch recommendation_path(rec), params: {recommendation: {outcome_rating: "loved"}}
    assert_equal "loved", rec.reload.outcome_rating
  end

  test "rejects invalid status with 422" do
    sign_in_as users(:one)
    patch recommendation_path(recommendations(:marco_pending)),
      params: {recommendation: {status: "invalid"}},
      headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert_response :unprocessable_entity
  end

  test "returns turbo stream when requested" do
    sign_in_as users(:one)
    patch recommendation_path(recommendations(:marco_pending)),
      params: {recommendation: {status: "reading"}},
      headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "cannot update another user recommendation" do
    sign_in_as users(:one)
    patch recommendation_path(recommendations(:two)),
      params: {recommendation: {status: "reading"}}
    assert_response :not_found
  end
end
