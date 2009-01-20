require "rubygems"
require "spec"
require "sinatra"
require "sinatra/test/rspec"
require "rspec_hpricot_matchers"

Spec::Runner.configure do |config|
  config.include(RspecHpricotMatchers)
end

set :views => File.join(File.dirname(__FILE__), "..", "views"),
    :public => File.join(File.dirname(__FILE__), "..", "public")

ENV["RACK_ENV"] = "test"

require File.join(File.dirname(__FILE__), "..", "app")

module RequestSpecHelper
  def body
    @response.body
  end
end
