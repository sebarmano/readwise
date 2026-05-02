namespace :migrate_legacy_db do
  desc "Import books, recommenders, and recommendations from a legacy library.db"
  task run: :environment do
    db_path = ENV.fetch("LEGACY_DB") { abort "Usage: LEGACY_DB=path/to/library.db USER_EMAIL=you@example.com rails migrate_legacy_db:run" }
    email = ENV.fetch("USER_EMAIL") { abort "Usage: LEGACY_DB=path/to/library.db USER_EMAIL=you@example.com rails migrate_legacy_db:run" }

    user = User.find_by!(email_address: email)
    result = MigrateLegacyDb.run(db_path, user)

    puts "#{result[:books_imported]} books imported, #{result[:books_skipped]} skipped"
    puts "#{result[:recommenders_imported]} recommenders imported, #{result[:recommenders_skipped]} skipped"
    puts "#{result[:recommendations_imported]} recommendations imported, #{result[:recommendations_skipped]} skipped"
  end
end
