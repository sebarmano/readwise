require "test_helper"

class OllamaWarmupJobTest < ActiveJob::TestCase
  test "calls ensure_model_present! on OllamaClient" do
    calls = []
    fake_client = Object.new
    fake_client.define_singleton_method(:ensure_model_present!) { calls << :called }

    job = OllamaWarmupJob.new
    job.define_singleton_method(:build_client) { fake_client }
    job.perform_now

    assert_equal [:called], calls
  end

  test "does not raise on connection error" do
    fake_client = Object.new
    fake_client.define_singleton_method(:ensure_model_present!) { raise OllamaClient::ConnectionError, "refused" }

    job = OllamaWarmupJob.new
    job.define_singleton_method(:build_client) { fake_client }

    assert_nothing_raised { job.perform_now }
  end

  test "logs a warning on connection error" do
    fake_client = Object.new
    fake_client.define_singleton_method(:ensure_model_present!) { raise OllamaClient::ConnectionError, "timed out" }

    job = OllamaWarmupJob.new
    job.define_singleton_method(:build_client) { fake_client }

    io = StringIO.new
    old_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    job.perform_now
    Rails.logger = old_logger

    assert_match "timed out", io.string
  end
end
