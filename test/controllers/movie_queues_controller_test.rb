require 'test_helper'

class MovieQueuesControllerTest < ActionController::TestCase
  def setup
    @controller = MovieQueuesController.new
    UserServicesProxy.prepopulate File.join(Rails.root, 'data', 'users.json')
    MovieServicesProxy.prepopulate File.join(Rails.root, 'data', 'movies.json')
  end

  test 'create -- should create a queue for a user' do
    user_id = '1'
    sorted_movie_ids = '3,7,1,4,11'
    post :create, params: {user_id: user_id, sorted_movie_ids: sorted_movie_ids}
    assert_response :success
    assert_equal sorted_movie_ids, MovieQueues.get(user_id), 'should have created a movie queue but it did not'
  end

  test 'create -- should return an error if a required param is missing' do
    # required create params are missing
    post :create
    assert_response :bad_request
  end

  test 'create -- should return an error if an unknown movie id is found in the request' do
    MovieServicesProxy.stubs(:check_ids).returns(['unknown_id, good_id'])

    post :create, params: {user_id: '1', sorted_movie_ids: '3,7,1,4,11'}
    assert_response :bad_request
  end

end
