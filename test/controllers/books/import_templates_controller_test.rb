require "test_helper"

class Books::ImportTemplatesControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when unauthenticated" do
    get books_import_template_path
    assert_redirected_to new_session_path
  end

  test "downloads a CSV file with the expected headers" do
    sign_in_as users(:one)
    get books_import_template_path

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.headers["Content-Disposition"], "books_import_template.csv"

    headers = CSV.parse(response.body).first
    assert_equal %w[title author genre year_read rating notes], headers
  end
end
