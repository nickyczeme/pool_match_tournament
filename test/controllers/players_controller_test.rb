require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @player = { name: "John", ranking: 10, preferred_cue: "Cue 1" }
    DB.execute("DELETE FROM players")
    DB.execute("INSERT INTO players (id, name, ranking, preferred_cue) VALUES (1, 'John', 10, 'Cue 1')")
    DB.execute("INSERT INTO players (id, name, ranking, preferred_cue) VALUES (2, 'Jane', 20, 'Cue 2')")
    DB.execute("INSERT INTO players (id, name, ranking, preferred_cue) VALUES (3, 'Johnny', 30, 'Cue 1')")
    DB.execute("INSERT INTO players (id, name, ranking, preferred_cue) VALUES (4, 'Nicole', 40, 'Cue 2')")
  end

  # (GET /players)
  test "should get index" do
    get players_url
    assert_response :success
  end

  # (POST /players)
  test "should create player" do
    assert_difference("DB.execute('SELECT COUNT(*) FROM players').first[0]") do
      post players_url, params: { player: @player }
    end
    assert_response :created
  end

  # (GET /players/:id)
  test "should show player" do
    post players_url, params: { player: @player }
    player_id = DB.execute("SELECT id FROM players WHERE name = ?", @player[:name]).first["id"]

    get player_url(player_id)
    assert_response :success
  end

  # (PUT /players/:id)
  test "should update player" do
    post players_url, params: { player: @player }
    player_id = DB.execute("SELECT id FROM players WHERE name = ?", @player[:name]).first["id"]

    patch player_url(player_id), params: { player: { name: "Updated Name" } }
    updated_player = DB.execute("SELECT * FROM players WHERE id = ?", player_id).first

    assert_equal "Updated Name", updated_player["name"]
    assert_response :success
  end

  # (DELETE /players/:id)
  test "should destroy player" do
    post players_url, params: { player: @player }
    player_id = DB.execute("SELECT id FROM players WHERE name = ?", @player[:name]).first["id"]

    assert_difference("DB.execute('SELECT COUNT(*) FROM players').first[0]", -1) do
      delete player_url(player_id)
    end
    assert_response :success
  end

  test "should filter players by partial name" do
    get "/players?name=john"
    assert_response :success

    players = JSON.parse(@response.body)
    puts "Players Response (Name Filter): #{players}"
    assert_equal 2, players.length
  end

  test "should return empty result for no matches" do
    get "/players?name=notfound"
    assert_response :success

    players = JSON.parse(@response.body)
    puts "Players Response (No Matches): #{players}"
    assert_equal 0, players.length
  end
end
