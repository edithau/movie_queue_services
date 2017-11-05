
# XXX doc
class MovieQueuesController < ApplicationController
  class ClientError < StandardError
  end

  rescue_from StandardError, with: :return_service_error
  rescue_from ClientError, with: :return_client_error

  # return a user's movie queue
  def show
    user_id = params[:id]
    sorted_movie_ids = MovieQueues.get user_id
    movie_queue = Array.new.tap do |mq|
      if !sorted_movie_ids.nil?
        sorted_movie_ids.split(',').each_with_index do |mid, index|
          movie = MovieServicesProxy.get mid
          movie['rank'] = (index+1).to_s
          mq << movie
        end
      end
    end

    render json: movie_queue.to_json, status: :ok
  end

  # create a movie queue for an user
  def create
    uid = params[:user_id]
    mids = params[:sorted_movie_ids]
    validate_user uid
    validate_movies mids
    MovieQueues.create(uid, mids)
    head :created
  end

  # update a user's queue (re-rank a movie, add a movie to queue, delete a movie from queue)
  def update

  end

  # delete a user's queue
  def destroy

  end


  private

  def validate_user(uid)
    raise ClientError, 'Missing require param: user id' if uid.nil?
    raise ClientError, "User id #{uid} does not exist in the User Service" if UserServicesProxy.get(uid).nil?
  end

  def validate_movies(movie_ids)
    raise ClientError, 'Missing require param: sorted movie ids (sort by delivery schedule)' if movie_ids.nil?
    invalid_movie_ids = MovieServicesProxy.check_ids(movie_ids.split(','))
    raise ClientError, "Movie ids #{invalid_movie_ids} do not exist in the Movie Service" if !invalid_movie_ids.empty?
  end

  def return_client_error(error)
    render json: { message: error.message }, status: :bad_request
  end

  def return_service_error(error)
    print error.backtrace.join("\n")
    render json: { message: error.message }, status: :internal_server_error
  end
end
