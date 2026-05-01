require "json"

class RecommendationService
  def initialize(user, clarification: nil, ollama_client: OllamaClient.new)
    @user = user
    @clarification = clarification
    @ollama_client = ollama_client
  end

  def prompt
    parts = [reading_history_section]
    parts << claude_recs_section if claude_recs.any?
    parts << friend_recs_section if pending_friend_recs.any?
    parts << "## Clarification\n#{@clarification}" if @clarification
    parts << instructions
    parts.join("\n\n")
  end

  def call
    full_response = ""
    @ollama_client.chat_stream(messages: [{role: "user", content: prompt}]) do |chunk|
      full_response += chunk
    end
    parsed = JSON.parse(extract_json(full_response))
    persist(parsed)
  end

  private

  def reading_history_section
    books = @user.books.order(read_at: :desc).limit(50)
    lines = books.map { |b| "- \"#{b.title}\" by #{b.author} (#{b.genre}, #{b.year}) — #{b.rating}, #{b.pace}, #{b.mood}" }
    "## Reading History\n#{lines.join("\n")}"
  end

  def claude_recs_section
    lines = claude_recs.map { |r| "- \"#{r.book_title}\" by #{r.book_author} — #{r.status}#{outcome_label(r)}" }
    "## Past Claude Recommendations\n#{lines.join("\n")}"
  end

  def friend_recs_section
    lines = pending_friend_recs.map do |r|
      taste = taste_score(r.recommender)
      "- \"#{r.book_title}\" by #{r.book_author} — from #{r.recommender.name}#{taste}"
    end
    "## Friend Recommendations (active)\n#{lines.join("\n")}"
  end

  def instructions
    <<~PROMPT.strip
      ## Task
      Suggest 3–5 books based on the reading history above. Do NOT suggest books already listed.
      Return ONLY a JSON array, no other text:
      [{"title":"...","author":"...","genre":"...","reason":"...","source":"claude"}]
    PROMPT
  end

  def claude_recs
    @claude_recs ||= @user.recommendations
      .joins(:recommender)
      .where(recommenders: {recommender_type: :claude})
      .order(created_at: :desc)
  end

  def pending_friend_recs
    @pending_friend_recs ||= @user.recommendations
      .joins(:recommender)
      .where(recommenders: {recommender_type: :friend})
      .active
      .includes(:recommender)
      .order(created_at: :desc)
  end

  def outcome_label(rec)
    rec.outcome_rating? ? ", outcome: #{rec.outcome_rating}" : ""
  end

  def taste_score(recommender)
    score = recommender.fiction_match || recommender.nonfiction_match
    score ? " (taste match: #{score.round(2)})" : ""
  end

  def extract_json(text)
    text[/\[.*\]/m] || text
  end

  def persist(recs)
    recommender = claude_recommender
    recs.each do |rec|
      @user.recommendations.create!(
        recommender: recommender,
        book_title: rec["title"],
        book_author: rec["author"],
        reason: rec["reason"],
        status: :pending
      )
    end
  end

  def claude_recommender
    @user.recommenders.find_or_create_by!(recommender_type: :claude) do |r|
      r.name = "Claude"
    end
  end
end
