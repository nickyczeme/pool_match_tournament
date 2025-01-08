class MatchesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy]

  # GET /matches
  def index
    query = "SELECT * FROM matches"
    conditions = []
    params_array = []
  
    if params[:date]
      conditions << "DATE(start_time) = ?"
      params_array << params[:date]
    end
  
    if params[:status]
      current_time = Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")
  
      case params[:status]
      when "upcoming"
        conditions << "start_time > ?"
        params_array << current_time
      when "ongoing"
        conditions << "start_time <= ? AND (end_time IS NULL OR end_time > ?)"
        params_array << current_time << current_time
      when "completed"
        conditions << "end_time <= ?"
        params_array << current_time
      else
        render json: { error: "Invalid status value" }, status: :bad_request
        return
      end
    end
  
    query += " WHERE " + conditions.join(" AND ") unless conditions.empty?
  
    matches = DB.execute(query, *params_array)
    render json: matches
  end
  
  # POST /matches
  def create
    player1_id = params[:match][:player1_id]
    player2_id = params[:match][:player2_id]
    start_time = params[:match][:start_time]
    end_time = params[:match][:end_time]

    # Check player exists
    player1 = DB.execute("SELECT * FROM players WHERE id = ?", player1_id).first
    player2 = DB.execute("SELECT * FROM players WHERE id = ?", player2_id).first

    if player1.nil? || player2.nil?
      missing_players = []
      missing_players << "Player 1" if player1.nil?
      missing_players << "Player 2" if player2.nil?
      render json: { error: "Player does not exist: #{missing_players.join(', ')}" }, status: :not_found
      return
    end

    if player1_id == player2_id
      render json: { error: "Player 1 and Player 2 cannot be the same" }, status: :bad_request
      return
    end
  
    DB.execute("BEGIN IMMEDIATE")
  
    begin
      
      # Checks conflicting match for Player 1
      if (conflicting_match = overlapping_match?(player1_id, start_time, end_time))
        DB.execute("ROLLBACK")
        render json: { error: "Player 1 is already scheduled for a match from #{conflicting_match['start_time']} to #{conflicting_match['end_time']}" }, status: :conflict
        return
      end
      
      # Checks conflicting match for Player 2
      if (conflicting_match = overlapping_match?(player2_id, start_time, end_time))
        DB.execute("ROLLBACK")
        render json: { error: "Player 2 is already scheduled for a match from #{conflicting_match['start_time']} to #{conflicting_match['end_time']}" }, status: :conflict
        return
      end
  
      query = "INSERT INTO matches (player1_id, player2_id, start_time, end_time, table_number) VALUES (?, ?, ?, ?, ?)"
      DB.execute(query, player1_id, player2_id, start_time, end_time, params[:match][:table_number])
  
      DB.execute("COMMIT")
      render json: { message: "Match created successfully" }, status: :created
  
    rescue => e
      DB.execute("ROLLBACK")
      render json: { error: "Error: #{e.message}" }, status: :internal_server_error
    end
  end

  # GET /matches/:id
  def show
    match = DB.execute("SELECT * FROM matches WHERE id = ?", params[:id]).first
    if match
      render json: match
    else
      render json: { error: "Match not found" }, status: :not_found
    end
  end

  # PUT /matches/:id
  def update
    match = DB.execute("SELECT * FROM matches WHERE id = ?", params[:id]).first
    unless match
      render json: { error: "Match not found" }, status: :not_found
      return
    end

    # Checks that the winner is one of the 2 players
    if params[:match][:winner_id]
      winner_id = params[:match][:winner_id].to_i
      player1_id = match["player1_id"]
      player2_id = match["player2_id"]
  
      unless [player1_id, player2_id].include?(winner_id)
        render json: { error: "Winner must be either Player 1 or Player 2" }, status: :unprocessable_entity
        return
      end
    end

    start_time = params[:match][:start_time] || match["start_time"]
    end_time = params[:match][:end_time] || match["end_time"]

    # Looks for conflicting matches before updating
    if (conflicting_match = overlapping_match?(match["player1_id"], start_time, end_time, match["id"]))
      render json: { error: "Player 1 is already scheduled for a match from #{conflicting_match['start_time']} to #{conflicting_match['end_time']}" }, status: :unprocessable_entity
      return
    end

    if (conflicting_match = overlapping_match?(match["player2_id"], start_time, end_time, match["id"]))
      render json: { error: "Player 2 is already scheduled for a match from #{conflicting_match['start_time']} to #{conflicting_match['end_time']}" }, status: :unprocessable_entity
      return
    end
  
    updates = []
    params[:match].each do |key, value|
      updates << "#{key} = ?"
    end
  
    if updates.empty?
      render json: { error: "No valid fields to update" }, status: :unprocessable_entity
      return
    end
  
    query = "UPDATE matches SET #{updates.join(", ")} WHERE id = ?"
    DB.execute(query, *params[:match].values, params[:id])
  
    render json: { message: "Match updated successfully" }
  end
  

  # DELETE /matches/:id
  def destroy
    DB.execute("DELETE FROM matches WHERE id = ?", params[:id])
    render json: { message: "Match deleted successfully" }
  end

  private

  def overlapping_match?(player_id, start_time, end_time, exclude_match_id = nil)
    query = <<-SQL
      SELECT * FROM matches
      WHERE (player1_id = ? OR player2_id = ?)
      AND (
        (? BETWEEN start_time AND end_time) OR
        (? BETWEEN start_time AND end_time) OR
        (start_time BETWEEN ? AND ?)
      )
    SQL
  
    # This is for the update 
    query += " AND id != ?" if exclude_match_id
  
    params = [player_id, player_id, start_time, end_time, start_time, end_time]
    params << exclude_match_id if exclude_match_id
  
    DB.execute(query, *params).first
  end
end
