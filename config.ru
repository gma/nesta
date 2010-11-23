if( ENV['RACK_ENV'] == 'production' )
  ENV['GEM_PATH'] = "/home/cfurrow/.gems"
  Gem.clear_paths
end
require "rack"
require "rubygems"
require "sinatra"
require "./app"

run Nesta::App
