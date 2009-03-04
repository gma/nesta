require "rubygems"
require "spec"
require "sinatra"
require "spec/interop/test"
require "sinatra/test"
require "rspec_hpricot_matchers"

Spec::Runner.configure do |config|
  config.include(RspecHpricotMatchers)
end

set :views => File.join(File.dirname(__FILE__), "..", "views"),
    :public => File.join(File.dirname(__FILE__), "..", "public")

set :environment, :test

require File.join(File.dirname(__FILE__), "..", "app")

module RequestSpecHelper
  def body
    @response.body
  end
end
