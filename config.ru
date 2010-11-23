if( ENV['DREAMHOST'] )
  ENV['GEM_PATH'] = "/home/cfurrow/.gems"
  Gem.clear_paths
end
require "rubygems"
require "sinatra"
require "./app"

run Nesta::App
