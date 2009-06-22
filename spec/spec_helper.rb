require "rubygems"
require "spec"
require "spec/interop/test"
require "rack/test"
require "rspec_hpricot_matchers"
require "sinatra"

Test::Unit::TestCase.send :include, Rack::Test::Methods

Spec::Runner.configure do |config|
  config.include(RspecHpricotMatchers)
end

set :views => File.join(File.dirname(__FILE__), "..", "views"),
    :public => File.join(File.dirname(__FILE__), "..", "public")

set :environment, :test

require File.join(File.dirname(__FILE__), "..", "app")

module RequestSpecHelper
  def app
    Sinatra::Application
  end
  
  def body
    last_response.body
  end
end
