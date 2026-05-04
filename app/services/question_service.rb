class QuestionService
  FIRST_TURN_PROMPT = <<~PROMPT.strip
    You are a knowledgeable reading guide with the user's reading history.
    Always ask ONE short, focused follow-up question — even if the user stated a preference.
    Probe for something they haven't mentioned yet: era (classic vs modern), mood, pace,
    or what to avoid. Under 30 words. No greeting. Just the question.
  PROMPT

  FOLLOWUP_PROMPT = <<~PROMPT.strip
    You are a knowledgeable reading guide with the user's reading history.
    If you now have enough context to make a confident recommendation, respond with exactly
    "[READY]" and nothing else. Otherwise ask ONE more short, focused question.
    Under 30 words. No greeting. Just the question or [READY].
  PROMPT

  def initialize(user, clarification: nil, messages: [], ollama_client: OllamaClient.new)
    @user = user
    @clarification = clarification
    @messages = messages
    @ollama_client = ollama_client
  end

  def call(&on_chunk)
    @ollama_client.chat_stream(messages: build_messages, &on_chunk)
  end

  private

  def build_messages
    system_prompt = @messages.empty? ? FIRST_TURN_PROMPT : FOLLOWUP_PROMPT
    [
      {role: "system", content: system_prompt},
      {role: "user", content: context_message},
      *@messages
    ]
  end

  def context_message
    parts = []
    books = @user.books.order(read_at: :desc).limit(10)
    if books.any?
      lines = books.map { |b| "- \"#{b.title}\" by #{b.author} (#{b.rating})" }
      parts << "Recent reading:\n#{lines.join("\n")}"
    end
    parts << "User's stated preference: #{@clarification}" if @clarification
    parts.any? ? parts.join("\n\n") : "I haven't read anything yet."
  end
end
