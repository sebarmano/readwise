require "test_helper"

class RecommendersControllerTest < ActionDispatch::IntegrationTest
  test "index redirects to sign in when unauthenticated" do
    get recommenders_path
    assert_redirected_to new_session_path
  end

  test "index renders successfully for signed-in user" do
    sign_in_as users(:one)
    get recommenders_path
    assert_response :success
  end

  test "index returns only friend recommenders for current user" do
    sign_in_as users(:one)
    get recommenders_path
    assert_includes @controller.instance_variable_get(:@recommenders), recommenders(:marco)
    assert_not_includes @controller.instance_variable_get(:@recommenders), recommenders(:one)
    assert_not_includes @controller.instance_variable_get(:@recommenders), recommenders(:two)
  end
end
