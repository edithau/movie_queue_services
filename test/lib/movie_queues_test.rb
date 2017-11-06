require 'test_helper'

class MovieQueuesTest < ActiveSupport::TestCase
  def teardown
    MovieQueues.reset
  end

  test '.update_queue' do
    uid = '1'
    sorted_movie_ids = '3,7,4,11'
    MovieQueues.create uid, sorted_movie_ids

    # add a movie at the end of the queue
    MovieQueues.update_queue uid, '5', '99'
    assert_equal '3,7,4,11,5', MovieQueues.queued_ids('1'),
                 'incorrect queue state'

    # remove a movie
    MovieQueues.update_queue uid, '3', '-1'
    assert_equal '7,4,11,5', MovieQueues.queued_ids('1'),
                 'incorrect queue state'

    # move a movie from first in queue to second
    MovieQueues.update_queue uid, '7', '1'
    assert_equal '4,7,11,5', MovieQueues.queued_ids('1'),
                 'incorrect queue state'

  end


end