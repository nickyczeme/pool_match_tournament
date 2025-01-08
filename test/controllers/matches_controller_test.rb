require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    DB.execute("DROP TABLE IF EXISTS players")
    DB.execute("DROP TABLE IF EXISTS matches")
  
    DB.execute <<-SQL
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL,
        ranking INTEGER DEFAULT 0,
        preferred_cue VARCHAR(100)
      );
    SQL
  
    DB.execute <<-SQL
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
    SQL
  
    DB.execute("INSERT INTO players (name, ranking, preferred_cue) VALUES ('John', 10, 'Cue A')")
    DB.execute("INSERT INTO players (name, ranking, preferred_cue) VALUES ('Jane', 20, 'Cue B')")
    DB.execute("INSERT INTO players (name, ranking, preferred_cue) VALUES ('Nicole', 30, 'Cue C')")
  
    # Insertar partidos de prueba
    DB.execute("INSERT INTO matches (player1_id, player2_id, start_time, end_time, table_number) VALUES (1, 2, DATETIME('now', '-30 minutes'), DATETIME('now', '+30 minutes'), 1)") # Ongoing
    DB.execute("INSERT INTO matches (player1_id, player2_id, start_time, end_time, table_number) VALUES (1, 2, DATETIME('now', '-2 hours'), DATETIME('now', '-1 hour'), 2)") # Completed
    DB.execute("INSERT INTO matches (player1_id, player2_id, start_time, end_time, table_number) VALUES (1, 2, DATETIME('now', '+1 hour'), DATETIME('now', '+2 hours'), 3)") # Upcoming
  end
  
  # GET /matches
  test "should get index" do
    get "/matches"
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal 3, body.count
  end

  # GET /matches/:id
  test "should show a match" do
    get "/matches/1"
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal 1, body["id"]
    assert_equal 1, body["player1_id"]
    assert_equal 2, body["player2_id"]
  end


  # Test: POST /matches
  test "should create a match" do
    post "/matches", params: {
      match: {
        player1_id: 1,
        player2_id: 2,
        start_time: "2025-01-04 15:00:00",
        table_number: 1
      }
    }
    assert_response :created
    body = JSON.parse(@response.body)
    assert_equal "Match created successfully", body["message"]
  end

  # Test: POST /matches (Error if players do not exist)
  test "should not create match if players do not exist" do
    post "/matches", params: {
      match: {
        player1_id: 99,
        player2_id: 100,
        start_time: "2025-01-04 15:00:00",
        table_number: 1
      }
    }
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_includes body["error"], "Player does not exist"
  end

  # Test: PUT /matches/:id
  test "should update a match" do
    put "/matches/1", params: {
      match: {
        end_time: "2025-01-04 16:00:00",
        winner_id: 1
      }
    }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "Match updated successfully", body["message"]
  end

  # Test: DELETE /matches/:id
  test "should delete a match" do
    delete "/matches/1"
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "Match deleted successfully", body["message"]
  end

  # Test: POST /matches (Overlap matches)
  test "should not allow overlapping matches for the same player" do
    DB.execute("INSERT INTO matches (player1_id, player2_id, start_time, end_time, table_number) VALUES (1, 2, '2025-01-04 15:00:00', '2025-01-04 16:00:00', 1)")

    post "/matches", params: {
      match: {
        player1_id: 1,
        player2_id: 3,
        start_time: "2025-01-04 15:30:00",
        end_time: "2025-01-04 16:30:00",
        table_number: 1
      }
    }
    assert_response :conflict
    body = JSON.parse(@response.body)
    assert_equal "Player 1 is already scheduled for a match from 2025-01-04 15:00:00 to 2025-01-04 16:00:00", body["error"]
  end

  # Test: PUT /matches/:id (Error if winner_id is not one of the players)
  test "should not update match if winner_id is not one of the players" do
    put "/matches/1", params: {
      match: {
        winner_id: 3
      }
    }
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal "Winner must be either Player 1 or Player 2", body["error"]
  end

  test "should filter ongoing matches" do
    get "/matches?status=ongoing"
    assert_response :success

    matches = JSON.parse(@response.body)
    puts "Matches Ongoing: #{matches}"
    assert_equal 1, matches.length
    assert_equal 1, matches.first["table_number"]
  end

  test "should filter upcoming matches" do
    get "/matches?status=upcoming"
    assert_response :success

    matches = JSON.parse(@response.body)
    puts "Matches Upcoming: #{matches}"
    assert_equal 1, matches.length
    assert_equal 3, matches.first["table_number"]
  end

  test "should filter completed matches" do
    get "/matches?status=completed"
    assert_response :success

    matches = JSON.parse(@response.body)
    puts "Matches Completed: #{matches}"
    assert_equal 1, matches.length
    assert_equal 2, matches.first["table_number"]
  end

  test "should filter matches by date" do
    date = Time.now.utc.strftime("%Y-%m-%d")
    get "/matches?date=#{date}"
    assert_response :success

    matches = JSON.parse(@response.body)
    puts "Matches Date Filter: #{matches}"
    assert_equal 3, matches.length
  end

  test "should update player rankings after match is completed" do
    # Completar un partido y declarar un ganador
    get "/matches/1"
    assert_response :success
    body = JSON.parse(@response.body)
    player_id_1 = body["player1_id"]
    player_id_2 =  body["player2_id"]

    player1 = DB.execute("SELECT * FROM players WHERE id = ?", player_id_1).first
    player2 = DB.execute("SELECT * FROM players WHERE id = ?", player_id_2).first

    ranking_before_winner_player_1 = player1['ranking']
    ranking_before_winner_player_2 = player2['ranking']

    put "/matches/1", params: {
      match: {
        end_time: "2025-01-04 16:00:00",
        winner_id: player_id_1
      }
    }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "Match updated successfully", body["message"]

    player1 = DB.execute("SELECT * FROM players WHERE id = ?", player_id_1).first
    player2 = DB.execute("SELECT * FROM players WHERE id = ?", player_id_2).first
  
    assert_equal 1, player1["ranking"] - ranking_before_winner_player_1
    assert_equal 1, ranking_before_winner_player_2 - player2["ranking"]
  end  
end
