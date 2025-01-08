class PlayersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy]

  # GET /players
  def index
    if params[:name]
      name_filter = "%#{params[:name]}%"
      players = DB.execute("SELECT * FROM players WHERE name LIKE ?", name_filter)
    else
      players = DB.execute("SELECT * FROM players")
    end
    render json: players
  end

  # POST /players
  def create
    if params[:player][:name].blank?
      render json: { error: "Name can't be blank" }, status: :bad_request
      return
    end

    query = "INSERT INTO players (name, ranking, preferred_cue) VALUES (?, ?, ?)"
    DB.execute(query, params[:player][:name], params[:player][:ranking], params[:player][:preferred_cue])
    render json: { message: "Player created successfully" }, status: :created
  end

  # GET /players/:id
  def show
    player = DB.execute("SELECT * FROM players WHERE id = ?", params[:id]).first
    if player
      render json: player
    else
      render json: { error: "Player not found" }, status: :not_found
    end
  end

  def update
    player = DB.execute("SELECT * FROM players WHERE id = ?", params[:id]).first
    unless player
      render json: { error: "Player not found" }, status: :not_found
      return
    end
  
    updates = []
    params[:player].each do |key, value|
      updates << "#{key} = ?"
    end
  
    if updates.empty?
      render json: { error: "No valid fields to update" }, status: :unprocessable_entity
      return
    end
  
    query = "UPDATE players SET #{updates.join(", ")} WHERE id = ?"
    DB.execute(query, *params[:player].values, params[:id])
  
    render json: { message: "Player updated successfully" }
  end

  # DELETE /players/:id
  def destroy
    DB.execute("DELETE FROM players WHERE id = ?", params[:id])
    render json: { message: "Player deleted successfully" }, status: :ok
  end
end
