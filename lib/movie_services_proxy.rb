require 'rest-client'

# this is a wrapper class for the Movie Services.
# 1. pre-populate X most recently rented movies to it's cache (redis)
# 2. return movie info from cache if the movie is present
# 3. request movie info from source (Movie Services) if cache missed; add the requested Movie to cache
class MovieServicesProxy

  class << self

    def get(id)
      redis.hgetall(key(id))
    end

    def check_ids(ids)
      cache_missed_ids = ids.select { |id| get(id).empty? }
      newly_cached_ids = cache_missed_ids.empty? ? [] : get_from_source(cache_missed_ids)
      invalid_ids = cache_missed_ids - newly_cached_ids
      invalid_ids
    end

    def prepopulate(json_file=nil)
      if !json_file.nil?
        file = File.read(json_file)
        movies = JSON.parse(file)
      else
        # service endpoint returns default number of most recently rented movies required_fields
        response = RestClient.get service_endpoint params: { fields: required_fields }
        raise "Cannot pre-populate Movies from endpoint #{service_endpoint}" if response != '200'
        movies = JSON.parse(response.body)
      end

      clear_cache
      movies.each do |movie|
        redis.hmset(key(movie['id']),
                    'id', movie['id'], 'name', movie['name'], 'year', movie['year'], 'genre', movie['genre'])
      end
      movies
    end

    def clear_cache
      redis.flushdb
    end

    private

    def service_endpoint
      'http://localhost:3003/movies'  # XXX should move to configuration file
    end

    # xxx - not the same error handling process for prepop and real time.  refactor!
    def get_from_source(ids)
      response = RestClient.get service_endpoint + '?ids=' + ids.join(','), params: { fields: required_fields }
      raise "Movie Services #{service_endpoint} returns status #{response.code}" if response.code != 200
      movies = JSON.parse(response.body)
      movies.each do |movie|
        redis.hmset(key(movie['id']),
                    'id', movie['id'], 'name', movie['name'], 'year', movie['year'], 'genre', movie['genre'])
      end
      ids
    # rescue => e
    #   raise e, "Cannot connect to Movie Services endpoint #{service_endpoint}"
    end

    def required_fields
      # the movie queue service only needs the movie name, genre, and year from the movie service
      'id,name,year,genre'
    end


    def redis
      $movie_redis
    end

    def key(id)
      # key prefix + uid is the key
      'm:' + id.to_s
    end
  end
end

