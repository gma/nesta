require "rubygems"
require "sinatra"

APP_ROOT = File.dirname(File.dirname(__FILE__))

set :run         => false,
    :environment => :production,
    :root        => APP_ROOT,
    :views       => APP_ROOT + "/views",
    :public      => APP_ROOT + "/public"
 
require File.join(APP_ROOT, "app.rb")
 
run Sinatra.application
