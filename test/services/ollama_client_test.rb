require "test_helper"

class OllamaClientTest < ActiveSupport::TestCase
  # --- helpers ---

  def fake_http(responses = {}, status = "200")
    fake_conn = Object.new
    fake_conn.define_singleton_method(:read_timeout=) { |_| }
    fake_conn.define_singleton_method(:open_timeout=) { |_| }
    fake_conn.define_singleton_method(:start) { |&blk| blk.call(fake_conn) }
    fake_conn.define_singleton_method(:request) do |req, &blk|
      body = responses.fetch(req.path, "{}")
      resp = Object.new
      resp.define_singleton_method(:code) { status }
      resp.define_singleton_method(:body) { body }
      resp.define_singleton_method(:read_body) { |&b| b ? body.each_line { |l| b.call(l) } : body }
      blk ? blk.call(resp) : resp
    end
    Class.new.tap { |c| c.define_singleton_method(:new) { |*| fake_conn } }
  end

  def stub_ollama_http_error(code:, error_message:)
    body = {"error" => error_message}.to_json
    fake_http({"/api/chat" => body}, code.to_s)
  end

  def stub_ollama_chat(response:)
    body = {"message" => {"content" => response}}.to_json
    fake_http("/api/chat" => body)
  end

  def stub_ollama_stream(chunks:)
    lines = chunks.map { |c| {"message" => {"content" => c}, "done" => false}.to_json + "\n" }
    lines << {"message" => {"content" => ""}, "done" => true}.to_json + "\n"
    fake_http("/api/chat" => lines.join)
  end

  def stub_ollama_tags(models:)
    body = {"models" => models.map { |m| {"name" => m} }}.to_json
    fake_http("/api/tags" => body)
  end

  # --- chat ---

  test "chat returns response string" do
    client = OllamaClient.new(http: stub_ollama_chat(response: "The answer is 42"))
    assert_equal "The answer is 42", client.chat(messages: [{role: "user", content: "question"}])
  end

  test "chat sends model and messages in request body" do
    sent_body = nil
    fake_conn = Object.new
    fake_conn.define_singleton_method(:read_timeout=) { |_| }
    fake_conn.define_singleton_method(:open_timeout=) { |_| }
    fake_conn.define_singleton_method(:start) { |&blk| blk.call(fake_conn) }
    fake_conn.define_singleton_method(:request) do |req, &blk|
      sent_body = JSON.parse(req.body)
      resp = Object.new
      resp.define_singleton_method(:body) { {"message" => {"content" => "ok"}}.to_json }
      blk ? blk.call(resp) : resp
    end
    http = Class.new.tap { |c| c.define_singleton_method(:new) { |*| fake_conn } }

    OllamaClient.new(model: "llama3", http:).chat(messages: [{role: "user", content: "hi"}])

    assert_equal "llama3", sent_body["model"]
    assert_equal false, sent_body["stream"]
  end

  # --- chat_stream ---

  test "chat_stream yields chunks" do
    http = stub_ollama_stream(chunks: ["Hel", "lo", " World"])
    chunks = []
    OllamaClient.new(http:).chat_stream(messages: [{role: "user", content: "hi"}]) { |c| chunks << c }
    assert_equal "Hello World", chunks.join
  end

  test "chat_stream does not yield done chunk content" do
    http = stub_ollama_stream(chunks: ["Hi"])
    chunks = []
    OllamaClient.new(http:).chat_stream(messages: []) { |c| chunks << c }
    assert_equal ["Hi"], chunks
  end

  # --- model_present? ---

  test "model_present? returns true when model is listed" do
    http = stub_ollama_tags(models: ["llama3:latest"])
    assert OllamaClient.new(model: "llama3", http:).model_present?
  end

  test "model_present? returns true for exact model name match" do
    http = stub_ollama_tags(models: ["llama3:8b"])
    assert OllamaClient.new(model: "llama3:8b", http:).model_present?
  end

  test "model_present? returns false when model is absent" do
    http = stub_ollama_tags(models: ["mistral:latest"])
    assert_not OllamaClient.new(model: "llama3", http:).model_present?
  end

  # --- ensure_model_present! ---

  test "ensure_model_present! does nothing when model is already present" do
    pull_called = false
    fake_conn = Object.new
    fake_conn.define_singleton_method(:read_timeout=) { |_| }
    fake_conn.define_singleton_method(:open_timeout=) { |_| }
    fake_conn.define_singleton_method(:start) { |&blk| blk.call(fake_conn) }
    fake_conn.define_singleton_method(:request) do |req, &blk|
      pull_called = true if req.path == "/api/pull"
      body = (req.path == "/api/tags") ? {"models" => [{"name" => "llama3:latest"}]}.to_json : "{}"
      resp = Object.new
      resp.define_singleton_method(:body) { body }
      blk ? blk.call(resp) : resp
    end
    http = Class.new.tap { |c| c.define_singleton_method(:new) { |*| fake_conn } }

    OllamaClient.new(model: "llama3", http:).ensure_model_present!
    assert_not pull_called
  end

  test "ensure_model_present! calls pull when model is absent" do
    pull_called = false
    fake_conn = Object.new
    fake_conn.define_singleton_method(:read_timeout=) { |_| }
    fake_conn.define_singleton_method(:open_timeout=) { |_| }
    fake_conn.define_singleton_method(:start) { |&blk| blk.call(fake_conn) }
    fake_conn.define_singleton_method(:request) do |req, &blk|
      pull_called = true if req.path == "/api/pull"
      body = (req.path == "/api/tags") ? {"models" => []}.to_json : {"status" => "success"}.to_json
      resp = Object.new
      resp.define_singleton_method(:body) { body }
      blk ? blk.call(resp) : resp
    end
    http = Class.new.tap { |c| c.define_singleton_method(:new) { |*| fake_conn } }

    OllamaClient.new(model: "llama3", http:).ensure_model_present!
    assert pull_called
  end

  # --- ConnectionError ---

  test "raises ConnectionError when ollama unreachable" do
    OllamaClient.new(url: "http://localhost:1").tap do |client|
      assert_raises(OllamaClient::ConnectionError) { client.chat(messages: []) }
    end
  end

  test "chat_stream raises ConnectionError with ollama error message on non-200 response" do
    http = stub_ollama_http_error(code: 404, error_message: "model 'qwen2.5:7b' not found")
    client = OllamaClient.new(http:)
    err = assert_raises(OllamaClient::ConnectionError) do
      client.chat_stream(messages: [{role: "user", content: "hi"}]) { |c| }
    end
    assert_includes err.message, "model 'qwen2.5:7b' not found"
  end

  test "chat_stream raises ConnectionError with HTTP code when error body is not JSON" do
    fake_conn = Object.new
    fake_conn.define_singleton_method(:read_timeout=) { |_| }
    fake_conn.define_singleton_method(:open_timeout=) { |_| }
    fake_conn.define_singleton_method(:start) { |&blk| blk.call(fake_conn) }
    fake_conn.define_singleton_method(:request) do |_req, &blk|
      resp = Object.new
      resp.define_singleton_method(:code) { "500" }
      resp.define_singleton_method(:read_body) { |&b| b ? b.call("Internal Server Error") : "Internal Server Error" }
      blk ? blk.call(resp) : resp
    end
    http = Class.new.tap { |c| c.define_singleton_method(:new) { |*| fake_conn } }
    err = assert_raises(OllamaClient::ConnectionError) do
      OllamaClient.new(http:).chat_stream(messages: []) { |c| }
    end
    assert_includes err.message, "HTTP 500"
  end
end
