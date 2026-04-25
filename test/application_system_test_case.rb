require "test_helper"
require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1440, 900], browser_options: {"no-sandbox": nil})
end

Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite

  include SessionTestHelper

  private

  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    click_on "Sign in"
  end
end
