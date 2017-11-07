require 'rest-client'

# This is a proxy to read and cache users from a remote User Services.
#
# How caching works?
# - use .prepopulate to preload cache with most frequent access users (ie. 1000 most recently logged in users)
# - User Services queries should be served from cache unless cache missed
# - on cache missed, retrieve data from User Services and update cache

class UserServicesProxy

  class << self

    def get(uid)
      user = redis.hgetall(key(uid))
      if user.empty?
        # cache missed
        user = get_from_source uid
      end
      user
    end

    # preload cache from a file or http
    def prepopulate(json_file=nil)
      if !json_file.nil?
        file = File.read(json_file)
        users = JSON.parse(file)
      else
        endpoint = service_endpoint + '/last_logged_in_users'
        response = RestClient.get endpoint params: { fields: required_fields }
        raise "User Services #{endpoint} returns status #{response.code}" if response.code != 200
        users = JSON.parse(response.body)
      end

      clear_cache
      users.each do |user|
        redis.hmset(key(user['id']), 'lname', user['lname'], 'fname', user['fname'])
      end
      users
    end

    def clear_cache
      redis.flushdb
    end

    private

    def service_endpoint
      'http://localhost:3001'  # XXX should move to configuration file
    end

    def get_from_source(uid)
      Rails.logger.info("Cache Missed -- User")
      endpoint = service_endpoint + '/users/' + uid
      result = RestClient.get(endpoint, params: { fields: required_fields }){ |response, request, result, &block|
        if response.code == 404
          nil
        elsif response.code != 200
          raise "User Services #{endpoint} returns status #{response.code}"
        else
          user = JSON.parse(response.body)
          redis.hmset(key(user['id']), 'lname', user['lname'], 'fname', user['fname'])
          {'lname': user['lname'], 'fname': user['fname']}
        end
      }
      result
    end

    def required_fields
      # the movie queue service only needs the user name fields from the user service
      'id, lname, fname'
    end

    def redis
      $user_redis
    end

    def key(uid)
      # key prefix + uid is the key
      'u:' + uid.to_s
    end
  end
end