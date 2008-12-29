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
require_or_load "lib/models"

helpers do
  def article_path(article)
    "/articles/#{article.permalink}"
  end
end

get "/css/master.css" do
  content_type "text/css", :charset => "utf-8"
  sass :master
end

get "/" do
  @body_class = "home"
  @title = Nesta::Configuration.title
  @subheading = Nesta::Configuration.subheading
  @articles = Article.find_all
  haml :index
end

get "/:permalink" do
  @home_link = Nesta::Configuration.title
  @category = Category.find_by_permalink(params[:permalink])
  @title = "#{@category.heading} - #{Nesta::Configuration.title}"
  haml :category
end

get "/articles/:permalink" do
  @home_link = Nesta::Configuration.title
  @article = Article.find_by_permalink(params[:permalink])
  @title = "#{@article.heading} - #{Nesta::Configuration.title}"
  haml :article
end
