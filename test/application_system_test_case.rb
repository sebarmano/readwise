require "test_helper"
require "capybara/cuprite"
require "database_cleaner/active_record"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1440, 900], browser_options: {"no-sandbox": nil})
end

Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite

# System tests use truncation, not transactions. Puma runs in its own thread
# with its own DB connection — it can't see an uncommitted test transaction.
# Truncation commits data so every connection sees it.
DatabaseCleaner.strategy = :truncation

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite

  self.use_transactional_tests = false

  setup { DatabaseCleaner.start }
  teardown { DatabaseCleaner.clean }

  # Signs in via the browser form — use when testing the auth flow itself.
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    click_on "Sign in"
  end

  # Creates and returns a persisted user with a known password.
  def create_user(email: "test@example.com", password: "password")
    User.create!(email_address: email, password: password, password_confirmation: password)
  end
end
