require 'sinatra'
require 'minitest/autorun'

require File.expand_path('../lib/nesta/env', File.dirname(__FILE__))
require File.expand_path('../lib/nesta/app', File.dirname(__FILE__))

require_relative 'support/model_factory'
require_relative 'support/temporary_files'
require_relative 'support/test_configuration'
