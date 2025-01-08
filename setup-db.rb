require 'sqlite3'

db_name = ARGV[0] || 'db/development.sqlite3'

db = SQLite3::Database.new(db_name)

sql = File.read('setup.sql')
db.execute_batch(sql)

puts "Database setup completed successfully for #{db_name}."
