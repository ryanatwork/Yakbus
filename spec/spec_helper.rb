unless ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require File.join(File.dirname(__FILE__), '..', 'yakbus.rb')

require 'rspec'
require 'rack/test'
require 'webmock/rspec'
set :environment, :test

RSpec.configure do |conf|
  conf.include Rack::Test::Methods

  def fixture_path
    File.expand_path('../fixtures', __FILE__)
  end

  def fixture(file)
    File.new(fixture_path + '/' + file)
  end

end

def app
  Sinatra::Application
end


