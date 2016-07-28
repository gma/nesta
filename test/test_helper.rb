require 'sinatra'
require 'minitest/autorun'

require 'minitest/reporters'

reporter_setting = ENV.fetch('REPORTER', 'progress')
camel_case = reporter_setting.split(/_/).map { |word| word.capitalize }.join('')
Minitest::Reporters.use! Minitest::Reporters.const_get("#{camel_case}Reporter").new

require File.expand_path('../lib/nesta/env', File.dirname(__FILE__))
require File.expand_path('../lib/nesta/app', File.dirname(__FILE__))

require_relative 'support/model_factory'
require_relative 'support/temporary_files'
require_relative 'support/test_configuration'
