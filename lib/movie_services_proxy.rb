require 'rest-client'

# This is a proxy to read and cache movies from a remote Movie Services.
#
# How caching works?
# - use .prepopulate to preload cache with most frequent access movies (ie. 1000 top popular movies)
# - Movie Services queries should be served from cache unless cache missed
# - on cache missed, retrieve data from Movie Services and update cache

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

    # preload cache from a file or http
    def prepopulate(json_file=nil)
      if !json_file.nil?
        file = File.read(json_file)
        movies = JSON.parse(file)
      else
        endpoint = service_endpoint + '/popular_movies'
        response = RestClient.get endpoint params: { fields: required_fields }
        raise "Movie Services #{endpoint} returns status #{response.code}" if response.code != 200
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
      'http://localhost:3002'  # XXX should move to configuration file
    end

    def get_from_source(ids)
      Rails.logger.info("Cache Missed -- Movie")
      endpoint = service_endpoint + '/movies?ids=' + ids.join(',')
      result = RestClient.get(endpoint, params: { fields: required_fields }){ |response, request, result, &block|
        if response.code == 404
          []
        elsif response.code != 200
          raise "Movie Services #{endpoint} returns status #{response.code}"
        else
          movies = JSON.parse(response.body)
          movies.each do |movie|
            redis.hmset(key(movie['id']),
                        'id', movie['id'], 'name', movie['name'], 'year', movie['year'], 'genre', movie['genre'])
          end
          ids
        end
      }
      result
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

