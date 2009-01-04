require "rubygems"
require "spec"
require "sinatra"
require "sinatra/test/rspec"
require "rspec_hpricot_matchers"

Spec::Runner.configure do |config|
  config.include(RspecHpricotMatchers)
end

set_options :views => File.join(File.dirname(__FILE__), "..", "views"),
            :public => File.join(File.dirname(__FILE__), "..", "public")

require File.join(File.dirname(__FILE__), "model_factory")
require File.join(File.dirname(__FILE__), "..", "app")
