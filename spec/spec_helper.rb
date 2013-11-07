require 'rspec'
require 'rack/test'
require 'sinatra'
require 'test/unit'
require 'webrat'
require 'webrat/core/matchers'

module Nesta
  class App < Sinatra::Base
    set :environment, :test
    set :reload_templates, true
  end
end

require File.expand_path('../lib/nesta/env', File.dirname(__FILE__))
require File.expand_path('../lib/nesta/app', File.dirname(__FILE__))

module ConfigSpecHelper
  def stub_yaml_config
    @config = {}
    Nesta::Config.stub(:yaml_exists?).and_return(true)
    Nesta::Config.stub(:yaml_conf).and_return(@config)
  end

  def stub_config_key(key, value, options = {})
    stub_yaml_config unless @config
    if options[:for_environment]
      @config['test'] ||= {}
      @config['test'][key] = value
    else
      @config[key] = value
    end
  end

  def stub_configuration(options = {})
    stub_config_key('title', 'My blog', options)
    stub_config_key('subtitle', 'about stuff', options)
    stub_config_key(
        'content', temp_path('content'), options.merge(rack_env: true))
  end
end

module TempFileHelper
  TEMP_DIR = File.expand_path('tmp', File.dirname(__FILE__))

  def create_temp_directory
    FileUtils.mkdir_p(TempFileHelper::TEMP_DIR)
  end

  def remove_temp_directory
    FileUtils.rm_r(TempFileHelper::TEMP_DIR, force: true)
  end

  def temp_path(base)
    File.join(TempFileHelper::TEMP_DIR, base)
  end
end

RSpec.configure do |config|
  config.include(ConfigSpecHelper)
  config.include(TempFileHelper)
  config.include(Rack::Test::Methods)
end

module RequestSpecHelper
  include Webrat::Matchers

  def app
    Nesta::App
  end

  def body
    last_response.body
  end

  def assert_xpath(*args)
    body.should have_xpath(*args)
  end

  def assert_not_xpath(*args)
    body.should_not have_xpath(*args)
  end

  def assert_selector(*args)
    body.should have_selector(*args)
  end

  def assert_not_selector(*args)
    body.should_not have_selector(*args)
  end
end
