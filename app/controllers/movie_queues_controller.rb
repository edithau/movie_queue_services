class MovieQueuesController < ApplicationController
  class ClientError < StandardError
  end

  rescue_from StandardError, with: :return_service_error
  rescue_from ClientError, with: :return_client_error

  # return a user's movie queue
  # return an empty queue if the user does not have a queue
  def show
    user_id = params[:id]
    sort_by_field = params[:sort_by]
    order = params[:order]

    movie_queue = MovieQueues.get_queue user_id, sort_by_field
    movie_queue.reverse! if order == '1'  # sort by descending order

    render json: movie_queue.to_json, status: :ok
  end

  # create a movie queue for an user
  def create
    uid = params[:user_id]
    mids = params[:movie_ids]

    validate_user uid
    validate_movies mids

    MovieQueues.create(uid, mids)  # XXX .. refactor? should only accept queue upto max size

    head :created
  end

  # update a user's queue (re-rank a movie, add a movie to queue, delete a movie from queue)
  def update
    uid = params[:id]
    movie_id = params[:movie_id]
    new_rank = params[:new_rank]
    validate_movies movie_id

    updated_queue = MovieQueues.update_queue(uid, movie_id, new_rank)

    render json: updated_queue.to_json, status: :ok
  end

  # remove a user's queue
  def destroy
    uid = params[:id]
    MovieQueues.remove uid
    head :ok
  end


  private

  def validate_user(uid)
    raise ClientError, 'Missing require param: user id' if uid.nil?
    raise ClientError, "User id #{uid} does not exist in the User Service" if UserServicesProxy.get(uid).nil?
    raise ClientError, 'User already has a movie queue' if !MovieQueues.queued_ids(uid).nil?
  end

  def validate_movies(movie_ids)
    raise ClientError, 'Missing require param: movie ids (in ranked order) ' if movie_ids.nil?

    movie_ids = movie_ids.split(',')

    if movie_ids.size > MovieQueues.max_queue_size
      raise ClientError, "Queue size #{movie_ids.size} exceeds max queue size (#{MovieQueues.max_queue_size})"
    end

    dup_id = movie_ids.detect{ |e| movie_ids.count(e) > 1 }
    raise ClientError, "Duplicate id #{dup_id} in the movie ids param" if !dup_id.nil?

    invalid_movie_ids = MovieServicesProxy.check_ids(movie_ids)
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
