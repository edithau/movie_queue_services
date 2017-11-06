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
        # service endpoint returns default number of user required_fields
        response = RestClient.get service_endpoint params: { fields: required_fields }
        raise "Cannot pre-populate Users from endpoint #{service_endpoint}" if response != '200'
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
      'http://localhost:3002/users'  # XXX should move to configuration file
    end

    # xxx - not the same error handling process for prepop and real time.  refactor!
    def get_from_source(uid)
      response = RestClient.get service_endpoint + '/' + uid, params: { fields: required_fields }
      raise "User Services #{service_endpoint} returns status #{response.code}" if response.code != 200

      user = JSON.parse(response.body)
      redis.hmset(key(user['id']), 'lname', user['lname'], 'fname', user['fname'])
      {'lname': user['lname'], 'fname': user['fname']}
    # rescue => e
    #   raise e, "Cannot connect to User Services endpoint #{service_endpoint}"
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