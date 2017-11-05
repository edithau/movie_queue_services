class MovieQueues
  class << self

    def create(uid, movie_ids)
      redis.set(key(uid), movie_ids)
    end

    def get(uid)
      redis.get(key(uid))
    end

    private

    def redis
      $mq_redis
    end

    def key(uid)
      # key prefix + uid is the key
      'mq:' + uid
    end
  end
end