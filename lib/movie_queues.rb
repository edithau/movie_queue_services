class MovieQueues
  MAX_QUEUE_SIZE = 200
  class << self

    def create(uid, sorted_movie_ids)
      redis.set(key(uid), sorted_movie_ids)
    end

    def remove(uid)
      redis.del(key(uid))
    end

    def queued_ids(uid)
      redis.get(key(uid))
    end

    def get_queue(uid, sort_by_field)
      qmids = queued_ids(uid)
      get_movies(qmids, sort_by_field)
    end


    # re-rank queue rules:
    # new_rank < 0                    ----> remove movie from queue if present
    # new_rank == 0                   ----> move movie to first in the queue
    # new_rank > 0 && <= queue size   ----> move movie to new_rank position
    # new_rank > queue size           ----> move movie to end of queue
    def update_queue(uid, movie_id, new_rank)
      queue = queued_ids uid
      if queue.nil?
        raise 'No movie queue exist to update'
      end

      new_rank = new_rank.to_i

      queue = queue.split(',')
      queue.delete movie_id
      new_rank = queue.size if new_rank > queue.size
      # insert movie id to new pos
      queue.insert new_rank, movie_id  if (new_rank >= 0)
      queue = queue.join(',')
      redis.set(key(uid), queue)
      get_movies queue, nil
    end

    def reset
      redis.flushdb
    end

    def max_queue_size
      MAX_QUEUE_SIZE
    end

    private

    def get_movies(mids, sort_by_field)
      movies = []
      if !mids.nil?
        mids.split(',').each_with_index do |mid, index|
          movie = MovieServicesProxy.get mid
          movie['rank'] = index.to_s
          movies << movie
        end
        movies = movies.sort_by { |hash| hash[sort_by_field] } if !sort_by_field.nil?
      end
      movies
    end

    def redis
      $mq_redis
    end

    def key(uid)
      # key prefix + uid is the key
      'mq:' + uid
    end
  end
end