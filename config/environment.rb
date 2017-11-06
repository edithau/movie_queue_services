# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.logger = Logger.new(STDOUT)
Rails.application.initialize!



# for now..
ENV["PRELOAD_CACHE_DATA"] = 'true'

if ENV["PRELOAD_CACHE_DATA"].present?
  Rails.logger.info "Preload users and movies data to cache"
  UserServicesProxy.prepopulate File.join(Rails.root, 'data', 'users.json')
  MovieServicesProxy.prepopulate File.join(Rails.root, 'data', 'movies.json')
end
