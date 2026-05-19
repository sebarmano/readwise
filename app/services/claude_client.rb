class ClaudeClient
  API_ERRORS = [
    Anthropic::Errors::APIConnectionError,
    Anthropic::Errors::APITimeoutError
  ].freeze

  def initialize(sdk_client: default_sdk_client)
    @sdk = sdk_client
  end

  def chat(messages:)
    system_prompt, user_messages = split_messages(messages)
    params = build_params(system_prompt, user_messages)
    response = @sdk.messages.create(**params)
    response.content.first.text
  rescue *API_ERRORS => e
    raise LlmClient::ConnectionError, e.message
  end

  def chat_stream(messages:, &block)
    system_prompt, user_messages = split_messages(messages)
    params = build_params(system_prompt, user_messages)
    @sdk.messages.stream(**params) do |stream|
      stream.text.each(&block)
    end
  rescue *API_ERRORS => e
    raise LlmClient::ConnectionError, e.message
  end

  private

  def split_messages(messages)
    system_messages = messages.select { |m| m[:role].to_s == "system" }
    user_messages = messages.reject { |m| m[:role].to_s == "system" }
    system_prompt = system_messages.map { |m| m[:content] }.join("\n").presence
    [system_prompt, user_messages]
  end

  def build_params(system_prompt, user_messages)
    params = {
      model: ENV.fetch("CLAUDE_MODEL", "claude-sonnet-4-6"),
      max_tokens: 4096,
      messages: user_messages
    }
    params[:system] = system_prompt if system_prompt
    params
  end

  def default_sdk_client
    Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY", nil))
  end
end
