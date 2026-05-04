class QuestionService
  MIN_TURNS = 3
  MAX_TURNS = 10

  # Turn 0: always ask — genre/fiction/nonfiction/mood
  FIRST_TURN_PROMPT = <<~PROMPT.strip
    You are an expert reading guide with the user's complete reading history.
    Ask ONE focused question to understand what kind of book they're in the mood for RIGHT NOW.
    Cover: fiction vs non-fiction, specific genre, or current emotional need.
    Do NOT say you're ready or give recommendations yet — only ask.
    Under 25 words. No greeting. Just the question.
  PROMPT

  # Turn 1: always ask — pace, difficulty, length, era
  SECOND_TURN_PROMPT = <<~PROMPT.strip
    You are an expert reading guide. Based on the conversation so far, ask ONE more question.
    This time probe: reading pace they want (fast-paced vs slow-burn), difficulty level (easy vs challenging),
    book length (short vs epic), or era preference (modern vs classic).
    Do NOT say you're ready — only ask.
    Under 25 words. No greeting. Just the question.
  PROMPT

  # Turn 2: always ask — author familiarity preference
  THIRD_TURN_PROMPT = <<~PROMPT.strip
    You are an expert reading guide. Ask ONE more question about author preferences.
    If the user has read 3+ books by the same author, ask whether they'd enjoy more from that author
    or want to discover new voices. Otherwise ask: do they prefer sticking with authors they know
    or taking a chance on someone new?
    Do NOT say you're ready — only ask.
    Under 30 words. No greeting. Just the question.
  PROMPT

  # Turn 3+: may emit [READY] if enough context, otherwise ask 1 more question
  FOLLOWUP_PROMPT = <<~PROMPT.strip
    You are an expert reading guide. Review the full conversation.
    If you now have rich enough context for highly personalised recommendations, respond with exactly "[READY]".
    Otherwise ask ONE more short question on something not yet covered
    (e.g. dark vs light themes, mood/atmosphere, standalone vs series, specific things to avoid).
    Under 25 words. No greeting. Just the question or [READY].
  PROMPT

  # Turn 10+: force finish
  FORCE_READY = "[READY]"

  def initialize(user, clarification: nil, messages: [], ollama_client: OllamaClient.new)
    @user = user
    @clarification = clarification
    @messages = messages
    @ollama_client = ollama_client
  end

  def call(&on_chunk)
    # Short-circuit if we've hit max turns — no need to call the LLM
    if turn_count >= MAX_TURNS
      on_chunk&.call(FORCE_READY)
      return
    end
    @ollama_client.chat_stream(messages: build_messages, &on_chunk)
  end

  private

  def turn_count
    @messages.count { |m| m[:role].to_s == "user" }
  end

  def system_prompt
    case turn_count
    when 0 then FIRST_TURN_PROMPT
    when 1 then SECOND_TURN_PROMPT
    when 2 then THIRD_TURN_PROMPT
    else FOLLOWUP_PROMPT
    end
  end

  def build_messages
    [
      {role: "system", content: system_prompt},
      {role: "user", content: context_message},
      *@messages
    ]
  end

  def context_message
    parts = []
    books = @user.books.order(read_at: :desc).limit(25)

    if books.any?
      lines = books.map { |b| "- \"#{b.title}\" by #{b.author} (#{b.rating})" }
      parts << "Reading history:\n#{lines.join("\n")}"

      prolific = books.group_by(&:author).select { |_, bs| bs.size >= 3 }.keys
      parts << "Authors read 3+ times: #{prolific.join(", ")}" if prolific.any?
    end

    parts << "User's stated preference: #{@clarification}" if @clarification.present?
    parts.any? ? parts.join("\n\n") : "No reading history yet."
  end
end
