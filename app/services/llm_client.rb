module LlmClient
  ConnectionError = Class.new(StandardError)

  def self.default
    case ENV.fetch("LLM_PROVIDER", "ollama")
    when "claude" then ClaudeClient.new
    else OllamaClient.new
    end
  end
end
