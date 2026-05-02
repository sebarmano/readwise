require "sqlite3"

class MigrateLegacyDb
  # Maps legacy integer ratings to Book enum values (meh:1, liked:2, loved:3)
  RATING_MAP = {1 => "meh", 2 => "liked", 3 => "loved"}.freeze
  # Legacy recommender_type integers map to Rails enum (friend:0, claude:1); default friend
  RECOMMENDER_TYPE_MAP = {0 => "friend", 1 => "friend", 2 => "friend"}.freeze

  def self.run(db_path, user)
    new(db_path, user).run
  end

  def initialize(db_path, user)
    @db = SQLite3::Database.new(db_path.to_s, results_as_hash: true)
    @user = user
    @counts = {
      books_imported: 0,
      books_skipped: 0,
      recommenders_imported: 0,
      recommenders_skipped: 0,
      recommendations_imported: 0,
      recommendations_skipped: 0
    }
  end

  def run
    recommender_id_map = import_recommenders
    import_books
    import_recommendations(recommender_id_map)
    @counts
  ensure
    @db.close
  end

  private

  def import_books
    @db.execute("SELECT * FROM books") do |row|
      title = row["title"]
      if @user.books.exists?(title: title)
        @counts[:books_skipped] += 1
        next
      end

      @user.books.create!(
        title: title,
        author: row["author"],
        genre: row["genre"],
        year: row["year"],
        rating: RATING_MAP.fetch(row["rating"], "meh"),
        notes: row["notes"],
        read_at: row["read_at"],
        cover_url: row["cover_url"],
        mood: row["mood"],
        pace: row["pace"]
      )
      @counts[:books_imported] += 1
    end
  end

  def import_recommenders
    id_map = {}
    @db.execute("SELECT * FROM recommenders") do |row|
      existing = @user.recommenders.find_by(name: row["name"])
      if existing
        @counts[:recommenders_skipped] += 1
        id_map[row["id"]] = existing.id
        next
      end

      recommender = @user.recommenders.create!(
        name: row["name"],
        email_address: row["email_address"],
        recommender_type: RECOMMENDER_TYPE_MAP.fetch(row["recommender_type"], "friend"),
        fiction_match: row["fiction_match"],
        nonfiction_match: row["nonfiction_match"]
      )
      @counts[:recommenders_imported] += 1
      id_map[row["id"]] = recommender.id
    end
    id_map
  end

  def import_recommendations(recommender_id_map)
    @db.execute("SELECT * FROM recommendations") do |row|
      rails_recommender_id = recommender_id_map[row["recommender_id"]]
      next unless rails_recommender_id

      if @user.recommendations.exists?(
        book_title: row["book_title"],
        recommender_id: rails_recommender_id
      )
        @counts[:recommendations_skipped] += 1
        next
      end

      @user.recommendations.create!(
        recommender_id: rails_recommender_id,
        book_title: row["book_title"],
        book_author: row["book_author"],
        book_type: row["book_type"],
        reason: row["reason"],
        status: row["status"] || 0,
        outcome_rating: row["outcome_rating"],
        read_at: row["read_at"]
      )
      @counts[:recommendations_imported] += 1
    end
  end
end
