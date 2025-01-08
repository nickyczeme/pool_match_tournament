CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL,
        ranking INTEGER DEFAULT 0,
        preferred_cue VARCHAR(100)
      );
CREATE TABLE matches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player1_id INTEGER NOT NULL,
        player2_id INTEGER NOT NULL,
        start_time TIMESTAMP NOT NULL,
        end_time TIMESTAMP,
        winner_id INTEGER,
        table_number INTEGER,
        FOREIGN KEY(player1_id) REFERENCES players(id),
        FOREIGN KEY(player2_id) REFERENCES players(id),
        FOREIGN KEY(winner_id) REFERENCES players(id),
        CHECK(player1_id <> player2_id)
      );
