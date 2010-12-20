require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require './app'

run Nesta::App
