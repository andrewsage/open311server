ENV['RACK_ENV'] = 'test'

# Load the app
require_relative '../config/boot'

require 'rspec'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def app
  Open311App
end