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

  # new / create
  test "new redirects to sign in when unauthenticated" do
    get new_recommendation_path
    assert_redirected_to new_session_path
  end

  test "new renders the form" do
    sign_in_as users(:one)
    get new_recommendation_path
    assert_response :success
  end

  test "create builds a new recommender and recommendation" do
    sign_in_as users(:one)
    assert_difference ["Recommendation.count", "Recommender.count"] do
      post recommendations_path, params: {
        recommendation: {
          book_title: "Piranesi", book_author: "Susanna Clarke",
          recommended_by: "Totally New Friend", reason: "Magical"
        }
      }
    end
    assert_redirected_to recommendations_path
  end

  test "create reuses an existing recommender by name" do
    sign_in_as users(:one)
    assert_difference "Recommendation.count", 1 do
      assert_no_difference "Recommender.count" do
        post recommendations_path, params: {
          recommendation: {
            book_title: "Piranesi", book_author: "Susanna Clarke",
            recommended_by: recommenders(:marco).name
          }
        }
      end
    end
  end

  test "create sets status to pending and type to friend" do
    sign_in_as users(:one)
    post recommendations_path, params: {
      recommendation: {
        book_title: "Piranesi", book_author: "Susanna Clarke",
        recommended_by: "Lea"
      }
    }
    rec = Recommendation.last
    assert rec.pending?
    assert rec.recommender.friend?
  end

  test "create re-renders form when title is missing" do
    sign_in_as users(:one)
    assert_no_difference "Recommendation.count" do
      post recommendations_path, params: {
        recommendation: {book_title: "", book_author: "A", recommended_by: "Lea"}
      }
    end
    assert_response :unprocessable_entity
  end

  test "create re-renders form when recommended_by is blank" do
    sign_in_as users(:one)
    assert_no_difference ["Recommendation.count", "Recommender.count"] do
      post recommendations_path, params: {
        recommendation: {book_title: "Piranesi", book_author: "A", recommended_by: ""}
      }
    end
    assert_response :unprocessable_entity
  end
end
