$mq_redis = Rails.env.test? ? Redis.new(db:4) : Redis.new(db: 0)
$user_redis = Redis.new(db: 1)
$movie_redis = Redis.new(db: 2)
