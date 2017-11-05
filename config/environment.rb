# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

UserServicesProxy.prepopulate File.join(Rails.root, 'data', 'users.json')
MovieServicesProxy.prepopulate File.join(Rails.root, 'data', 'movies.json')