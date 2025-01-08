require 'sqlite3'

DB = SQLite3::Database.new(Rails.root.join("db", "development.sqlite3").to_s)

DB.results_as_hash = true
