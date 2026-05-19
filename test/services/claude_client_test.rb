require "test_helper"

class ClaudeClientTest < ActiveSupport::TestCase
  # --- helpers ---

  # Builds a fake Anthropic SDK client that records calls and returns canned responses.
  def fake_anthropic_client(chat_response: "Hello!", stream_chunks: ["Hel", "lo", "!"])
    fake_messages = Object.new

    # For #create (non-streaming chat)
    fake_messages.define_singleton_method(:create) do |**params|
      @last_create_params = params
      resp = Object.new
      resp.define_singleton_method(:content) do
        [Object.new.tap { |b| b.define_singleton_method(:text) { chat_response } }]
      end
      resp
    end
    fake_messages.define_singleton_method(:last_create_params) { @last_create_params }

    # For #stream (streaming)
    fake_messages.define_singleton_method(:stream) do |**params, &blk|
      @last_stream_params = params
      stream = Object.new
      stream.define_singleton_method(:text) do
        stream_chunks.each
      end
      blk ? blk.call(stream) : stream
    end
    fake_messages.define_singleton_method(:last_stream_params) { @last_stream_params }

    client = Object.new
    client.define_singleton_method(:messages) { fake_messages }
    client
  end

  def fake_erroring_client(error)
    fake_messages = Object.new
    fake_messages.define_singleton_method(:create) { |**| raise error }
    fake_messages.define_singleton_method(:stream) { |**| raise error }
    client = Object.new
    client.define_singleton_method(:messages) { fake_messages }
    client
  end

  # --- chat ---

  test "chat returns string content from response" do
    sdk = fake_anthropic_client(chat_response: "The answer is 42")
    client = ClaudeClient.new(sdk_client: sdk)
    result = client.chat(messages: [{role: "user", content: "what is 6*7?"}])
    assert_equal "The answer is 42", result
  end

  test "chat sends user messages (non-system) to messages param" do
    sdk = fake_anthropic_client
    client = ClaudeClient.new(sdk_client: sdk)
    messages = [{role: "user", content: "hi"}]
    client.chat(messages: messages)
    params = sdk.messages.last_create_params
    assert_equal [{role: "user", content: "hi"}], params[:messages]
  end

  test "chat extracts system messages into system param" do
    sdk = fake_anthropic_client
    client = ClaudeClient.new(sdk_client: sdk)
    messages = [
      {role: "system", content: "You are helpful"},
      {role: "user", content: "hi"}
    ]
    client.chat(messages: messages)
    params = sdk.messages.last_create_params
    assert_equal "You are helpful", params[:system]
    assert_equal [{role: "user", content: "hi"}], params[:messages]
  end

  test "chat raises LlmClient::ConnectionError on API connection error" do
    url = URI("https://api.anthropic.com")
    error = Anthropic::Errors::APIConnectionError.new(url: url)
    sdk = fake_erroring_client(error)
    client = ClaudeClient.new(sdk_client: sdk)
    assert_raises(LlmClient::ConnectionError) do
      client.chat(messages: [{role: "user", content: "hi"}])
    end
  end

  test "chat raises LlmClient::ConnectionError on API timeout" do
    url = URI("https://api.anthropic.com")
    error = Anthropic::Errors::APITimeoutError.new(url: url)
    sdk = fake_erroring_client(error)
    client = ClaudeClient.new(sdk_client: sdk)
    assert_raises(LlmClient::ConnectionError) do
      client.chat(messages: [{role: "user", content: "hi"}])
    end
  end

  # --- chat_stream ---

  test "chat_stream yields text chunks" do
    sdk = fake_anthropic_client(stream_chunks: ["Hel", "lo", " World"])
    client = ClaudeClient.new(sdk_client: sdk)
    chunks = []
    client.chat_stream(messages: [{role: "user", content: "hi"}]) { |c| chunks << c }
    assert_equal "Hello World", chunks.join
  end

  test "chat_stream extracts system messages into system param" do
    sdk = fake_anthropic_client(stream_chunks: ["ok"])
    client = ClaudeClient.new(sdk_client: sdk)
    messages = [
      {role: "system", content: "Be concise"},
      {role: "user", content: "hello"}
    ]
    client.chat_stream(messages: messages) { |_| }
    params = sdk.messages.last_stream_params
    assert_equal "Be concise", params[:system]
    assert_equal [{role: "user", content: "hello"}], params[:messages]
  end

  test "chat_stream raises LlmClient::ConnectionError on network failure" do
    url = URI("https://api.anthropic.com")
    error = Anthropic::Errors::APIConnectionError.new(url: url)
    sdk = fake_erroring_client(error)
    client = ClaudeClient.new(sdk_client: sdk)
    assert_raises(LlmClient::ConnectionError) do
      client.chat_stream(messages: [{role: "user", content: "hi"}]) { |_| }
    end
  end
end
