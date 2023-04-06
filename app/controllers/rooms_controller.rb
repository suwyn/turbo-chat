class RoomsController < ActionController::Base
  # disable token verification so we can load test
  protect_from_forgery except: :create

  # turn off the layout for load test
  # we want to isolate the test to the DB
  layout false

  def index
    ActiveRecord::Base.connected_to(role: :reading) do
      render json: {
        name: Room.connection.pool.db_config.name,
        role: Room.connection_pool.role,
        rooms: Room.last(75).map(&:name)
       }, status: 200
    end

    # use this instead for a single db configuration

    # render json: {
    #   name: Room.connection.pool.db_config.name,
    #   role: Room.connection_pool.role,
    #   rooms: Room.last(75).map(&:name)
    #  }, status: 200
  end

  def create
    Room.transaction do
      1.times do
        Room.create!(name: Faker::Games::Zelda.location)
      end
      # sleep 2.seconds
    end

    render plain: "success!, name: #{Room.connection.pool.db_config.name} role: #{Room.connection_pool.role}", status: 200
  end
end
