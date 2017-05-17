require 'capybara/dsl'

require_relative 'test_helper'

module Nesta
  class App < Sinatra::Base
    set :environment, :test
    set :reload_templates, true
  end

  module IntegrationTest
    include Capybara::DSL

    include ModelFactory
    include TestConfiguration

    def setup
      Capybara.app = App.new
    end

    def teardown
      Capybara.reset_sessions!
      Capybara.use_default_driver

      remove_temp_directory
      Nesta::FileModel.purge_cache
    end

    def assert_has_xpath(query, options = {})
      if ! page.has_xpath?(query, options)
        message = "not found in page: '#{query}'"
        message << ", #{options.inspect}" unless options.empty?
        fail message
      end
    end

    def assert_has_no_xpath(query, options = {})
      if page.has_xpath?(query, options)
        message = "found in page: '#{query}'"
        message << ", #{options.inspect}" unless options.empty?
        fail message
      end
    end

    def assert_has_css(query, options = {})
      if ! page.has_css?(query, options)
        message = "not found in page: '#{query}'"
        message << ", #{options.inspect}" unless options.empty?
        fail message
      end
    end

    def assert_has_no_css(query, options = {})
      if ! page.has_no_css?(query, options)
        message = "found in page: '#{query}'"
        message << ", #{options.inspect}" unless options.empty?
        fail message
      end
    end
  end
end
