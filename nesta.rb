require "rubygems"
require "sinatra"

def require_or_load(file)
  if Sinatra.env == :development
    load File.join(File.dirname(__FILE__), "#{file}.rb")
  else
    require file
  end
end

require_or_load "lib/configuration"

get "/css/master.css" do
  content_type "text/css", :charset => "utf-8"
  sass :master
end

get "/" do
  @title = Nesta::Configuration.title
  @subheading = Nesta::Configuration.subheading
  haml :index
end
