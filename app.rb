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
  def set_common_variables
    @categories = Category.find_all
    @home_link = Nesta::Configuration.title
    @google_analytics_code = Nesta::Configuration.google_analytics_code
  end
  
  def article_path(article)
    "/articles/#{article.permalink}"
  end

  def category_path(category)
    "/#{category.permalink}"
  end
  
  def base_url
    url = "http://#{request.host}"
    request.port == 80 ? url : url + ":#{request.port}"
  end  
  
  def article_url(article)
    base_url + "/articles/#{article.permalink}"
  end

  def nesta_atom_id_for_article(article)
    published = article.date ? article.date.strftime('%Y-%m-%d') : "no-date"
    "tag:#{request.host},#{published}:/articles/#{article.permalink}"
  end
  
  def atom_id(article = nil)
    if article
      article.atom_id || nesta_atom_id_for_article(article)
    else
      "tag:#{request.host},2009:/articles"
    end
  end
  
  def format_date(date)
    date.strftime("%d %B %Y")
  end
end

get "/css/master.css" do
  content_type "text/css", :charset => "utf-8"
  sass :master
end

get "/" do
  set_common_variables
  @body_class = "home"
  @title = Nesta::Configuration.title
  @subtitle = Nesta::Configuration.subtitle
  @articles = Article.find_all[0..7]
  haml :index
end

get "/:permalink" do
  set_common_variables
  @category = Category.find_by_permalink(params[:permalink])
  @title = "#{@category.heading} - #{Nesta::Configuration.title}"
  haml :category
end

get "/articles/:permalink" do
  set_common_variables
  @article = Article.find_by_permalink(params[:permalink])
  @title = "#{@article.heading} - #{Nesta::Configuration.title}"
  haml :article
end

get "/articles.xml" do
  @title = Nesta::Configuration.title
  @subtitle = Nesta::Configuration.subtitle
  @author = Nesta::Configuration.author
  @articles = Article.find_all.select { |a| a.date }[0..9]
  builder :atom
end
