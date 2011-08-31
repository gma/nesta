require 'rubygems'
require 'spec'
require 'spec/interop/test'
require 'rack/test'
require 'rspec_hpricot_matchers'
require 'sinatra'

Test::Unit::TestCase.send :include, Rack::Test::Methods

Spec::Runner.configure do |config|
  config.include(RspecHpricotMatchers)
end

module Nesta
  class App < Sinatra::Base
    set :environment, :test
    set :reload_templates, true
  end
end

require File.expand_path('../lib/nesta/env', File.dirname(__FILE__))
require File.expand_path('../lib/nesta/app', File.dirname(__FILE__))

module FixtureHelper
  FIXTURE_DIR = File.expand_path('fixtures', File.dirname(__FILE__))

  def create_fixtures_directory
    FileUtils.mkdir_p(FixtureHelper::FIXTURE_DIR)
  end

  def remove_fixtures
    FileUtils.rm_r(FixtureHelper::FIXTURE_DIR, :force => true)
  end
end

module RequestSpecHelper
  def app
    Nesta::App
  end
  
  def body
    last_response.body
  end
end

module ConfigSpecHelper
  include FixtureHelper

  def stub_yaml_config
    @config = {}
    Nesta::Config.stub!(:yaml_exists?).and_return(true)
    Nesta::Config.stub!(:yaml_conf).and_return(@config)
  end

  def stub_config_key(key, value, options = {})
    stub_yaml_config unless @config
    if options[:rack_env]
      @config['test'] ||= {}
      @config['test'][key] = value
    else
      @config[key] = value
    end
  end
  
  def stub_configuration(options = {})
    stub_config_key('title', 'My blog', options)
    stub_config_key('subtitle', 'about stuff', options)
    content_path = File.join(FixtureHelper::FIXTURE_DIR, 'content')
    stub_config_key('content', content_path, options.merge(:rack_env => true))
  end
end
