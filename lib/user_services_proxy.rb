require 'rest-client'

# this is a wrapper class for the User Services.
# 1. prepopulate X most recently logged in users to it's cache (redis)
# 2. return user info from cache if the user is present
# 3. request user info from source (User Service) if cache missed; add the requested user to cache
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
      endpoint = service_endpoint + '/users'
      response = RestClient.get endpoint + '/' + uid, params: { fields: required_fields }
      raise "User Services #{endpoint} returns status #{response.code}" if response.code != 200

      user = JSON.parse(response.body)
      redis.hmset(key(user['id']), 'lname', user['lname'], 'fname', user['fname'])
      {'lname': user['lname'], 'fname': user['fname']}
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