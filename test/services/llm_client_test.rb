require "test_helper"

class LlmClientTest < ActiveSupport::TestCase
  test "default returns OllamaClient when LLM_PROVIDER is unset" do
    with_env("LLM_PROVIDER" => nil) do
      assert_instance_of OllamaClient, LlmClient.default
    end
  end

  test "default returns OllamaClient when LLM_PROVIDER is ollama" do
    with_env("LLM_PROVIDER" => "ollama") do
      assert_instance_of OllamaClient, LlmClient.default
    end
  end

  test "default returns ClaudeClient when LLM_PROVIDER is claude" do
    with_env("LLM_PROVIDER" => "claude") do
      assert_instance_of ClaudeClient, LlmClient.default
    end
  end

  test "OllamaClient::ConnectionError is a LlmClient::ConnectionError" do
    assert OllamaClient::ConnectionError.ancestors.include?(LlmClient::ConnectionError),
      "OllamaClient::ConnectionError should inherit from LlmClient::ConnectionError"
  end

  test "LlmClient::ConnectionError is a StandardError" do
    assert LlmClient::ConnectionError.ancestors.include?(StandardError)
  end

  private

  def with_env(vars)
    old = vars.keys.to_h { |k| [k, ENV[k]] }
    vars.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
