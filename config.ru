require "rubygems"
require "sinatra"

APP_ROOT = File.dirname(__FILE__)

set :run         => false,
    :environment => :production,
    :root        => APP_ROOT,
    :views       => APP_ROOT + "/views",
    :public      => APP_ROOT + "/public"
 
require "app"
 
run Sinatra::Application
