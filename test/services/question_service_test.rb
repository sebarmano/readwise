require "test_helper"

class QuestionServiceTest < ActiveSupport::TestCase
  def stub_ollama(chunks: ["What genre are you in the mood for?"])
    client = Object.new
    client.define_singleton_method(:chat_stream) do |messages:, &blk|
      chunks.each { |c| blk&.call(c) }
    end
    client
  end

  # --- context_message ---

  test "context_message includes reading history" do
    service = QuestionService.new(users(:one), ollama_client: stub_ollama)
    assert_includes service.send(:context_message), books(:beloved).title
  end

  test "context_message includes known preferences when present" do
    service = QuestionService.new(users(:one), ollama_client: stub_ollama)
    assert_includes service.send(:context_message), "Known preferences"
    assert_includes service.send(:context_message), user_preferences(:slow_burn).signal
  end

  test "context_message omits known preferences when user has none" do
    user = User.create!(email_address: "qtest_nopref@example.com", password: "password")
    service = QuestionService.new(user, ollama_client: stub_ollama)
    assert_not_includes service.send(:context_message), "Known preferences"
  end

  # --- system prompt with directive ---

  test "system prompt includes do-not-ask directive when user has preferences" do
    captured_messages = nil
    client = Object.new
    client.define_singleton_method(:chat_stream) do |messages:, &blk|
      captured_messages = messages
      blk&.call("ok")
    end
    service = QuestionService.new(users(:one), ollama_client: client)
    service.call { |_| }
    system = captured_messages.find { |m| m[:role] == "system" }
    assert_includes system[:content], "do not ask about them again"
  end

  test "system prompt has no directive when user has no preferences" do
    captured_messages = nil
    client = Object.new
    client.define_singleton_method(:chat_stream) do |messages:, &blk|
      captured_messages = messages
      blk&.call("ok")
    end
    user = User.create!(email_address: "qtest_nopref2@example.com", password: "password")
    service = QuestionService.new(user, ollama_client: client)
    service.call { |_| }
    system = captured_messages.find { |m| m[:role] == "system" }
    assert_not_includes system[:content], "do not ask about them again"
  end

  # --- call behavior ---

  test "call streams chunks from ollama" do
    service = QuestionService.new(users(:one), ollama_client: stub_ollama(chunks: ["What genre?"]))
    received = []
    service.call { |c| received << c }
    assert_equal ["What genre?"], received
  end

  test "call short-circuits at MAX_TURNS" do
    messages = Array.new(QuestionService::MAX_TURNS) { {role: "user", content: "hi"} }
    received = []
    QuestionService.new(users(:one), messages: messages, ollama_client: stub_ollama).call { |c| received << c }
    assert_equal ["[READY]"], received
  end
end
