require 'test_helper'

class MovieQueuesControllerTest < ActionController::TestCase
  def setup
    @controller = MovieQueuesController.new
    MovieQueues.reset
    UserServicesProxy.prepopulate File.join(Rails.root, 'data', 'users.json')
    MovieServicesProxy.prepopulate File.join(Rails.root, 'data', 'movies.json')
  end

  def teardown
    MovieQueues.reset
  end

  test '#create -- should create a queue for a user' do
    user_id = '1'
    sorted_movie_ids = '3,7,1,4,11'
    UserServicesProxy.stubs(:get).returns({'id' => '1'})
    post :create, params: {user_id: user_id, movie_ids: sorted_movie_ids}
    assert_response :success
    assert_equal sorted_movie_ids, MovieQueues.queued_ids(user_id), 'should have created a movie queue but it did not'
  end

  test '#create -- should return an error if a required param is missing' do
    # required create params are missing
    post :create
    assert_response :bad_request
  end

  test '#create -- should return an error if an unknown movie id is found in the request' do
    MovieServicesProxy.stubs(:check_ids).returns(['unknown_id, good_id'])
    UserServicesProxy.stubs(:get).returns({'id' => '1'})
    post :create, params: {user_id: '1', movie_ids: '3,7,1,4,11'}
    assert_response :bad_request
  end

  test '#create -- should return error if requested movie queue size is larger than max size' do
    MovieQueues.stubs(:max_queue_size).returns 5
    UserServicesProxy.stubs(:get).returns({'id' => '1'})
    post :create, params: {user_id: '1', movie_ids: '1,2,3,4,5,6'}
    assert_response :bad_request
  end

  test '#show -- should return a user\'s movie queue' do
    uid = '1'
    MovieQueues.create(uid, '3,9')
    get :show, params: {id: uid}
    assert_response :ok
    assert_equal 2, JSON.parse(response.body).size,
                 'should have returned number of movie in the queue'
  end

  test '#show -- should return empty queue if there is no such user' do
    uid = 'fake_id'
    get :show, params: {id: uid}
    assert_response :ok
    assert_equal 0, JSON.parse(response.body).size,
                 'should have returned 0 if user does not exist'
  end

  test '#update -- add a movie to position 2 in the queue' do
    uid = '1'
    movie_ids = '3,7,4,11'
    MovieQueues.create(uid, movie_ids)
    put :update, params: {id: uid, movie_id: '9', new_rank: '2'}
    assert_response :ok
    assert_equal '3,7,9,4,11',MovieQueues.queued_ids(uid),
                 'movie queue is not in the correct order'
  end

  test '#destroy -- should remove a queue' do
    uid = '1'
    movie_ids = '3,7,4,11'
    MovieQueues.create(uid, movie_ids)
    delete :destroy, params: {id: uid}
    assert_response :ok
    assert_nil MovieQueues.queued_ids(uid), 'should have deleted movie queue'
  end


end