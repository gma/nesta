require "rubygems"
require "sinatra"
require "Builder"
require "Haml"

def require_or_load(file)
  if Sinatra::Application.environment == :development
    load File.join(File.dirname(__FILE__), "#{file}.rb")
  else
    require file
  end
end

require_or_load "lib/cache"
require_or_load "lib/configuration"
require_or_load "lib/models"

set :cache_dir, "cache"
set :cache_enabled, Nesta::Configuration.cache

helpers do
  def set_from_config(*variables)
    variables.each do |var|
      instance_variable_set("@#{var}", Nesta::Configuration.send(var))
    end
  end
  
  def set_common_variables
    @categories = Category.find_all
    @site_title = Nesta::Configuration.title
    set_from_config(:google_analytics_code)
  end

  def article_path(article)
    "#{Nesta::Configuration.article_prefix}/#{article.permalink}"
  end

  def category_path(category)
    "#{Nesta::Configuration.category_prefix}/#{category.permalink}"
  end
  
  def url_for(page)
    base = if page.is_a?(Article)
      base_url + Nesta::Configuration.article_prefix
    else
      base_url + Nesta::Configuration.category_prefix
    end
    [base, page.permalink].join("/")
  end
  
  def base_url
    url = "http://#{request.host}"
    request.port == 80 ? url : url + ":#{request.port}"
  end  
  
  def nesta_atom_id_for_article(article)
    published = article.date.strftime('%Y-%m-%d')
    "tag:#{request.host},#{published}:#{article_path(article)}"
  end
  
  def atom_id(article = nil)
    if article
      article.atom_id || nesta_atom_id_for_article(article)
    else
      "tag:#{request.host},2009:#{Nesta::Configuration.article_prefix}"
    end
  end
  
  def format_date(date)
    date.strftime("%d %B %Y")
  end
end

not_found do
  set_common_variables
  cache haml(:not_found)
end

error do
  set_common_variables
  cache haml(:error)
end unless Sinatra::Application.environment == :development

get "/css/master.css" do
  content_type "text/css", :charset => "utf-8"
  cache sass(:master)
end

get "/" do
  set_common_variables
  set_from_config(:title, :subtitle, :description, :keywords)
  @heading = @title
  @title = "#{@title} - #{@subtitle}"
  @articles = Article.find_all[0..7]
  @body_class = "home"
  cache haml(:index)
end

get "#{Nesta::Configuration.article_prefix}/:permalink" do
  set_common_variables
  @article = Article.find_by_permalink(params[:permalink])
  raise Sinatra::NotFound if @article.nil?
  @title = if @article.parent
    "#{@article.heading} - #{@article.parent.heading}"
  else
    "#{@article.heading} - #{Nesta::Configuration.title}"
  end
  @description = @article.description
  @keywords = @article.keywords
  @comments = @article.comments
  cache haml(:article)
end

get "/attachments/:filename.:ext" do
  file = File.join(
      Nesta::Configuration.attachment_path, "#{params[:filename]}.#{params[:ext]}")
  send_file(file, :disposition => nil)
end

get "#{Nesta::Configuration.article_prefix}.xml" do
  content_type :xml, :charset => "utf-8"
  set_from_config(:title, :subtitle, :author)
  @articles = Article.find_all.select { |a| a.date }[0..9]
  cache builder(:atom)
end

get "/sitemap.xml" do
  content_type :xml, :charset => "utf-8"
  @pages = Category.find_all + Article.find_all
  @last = @pages.map { |page| page.last_modified }.inject do |latest, this|
    this > latest ? this : latest
  end
  cache builder(:sitemap)
end

get "#{Nesta::Configuration.category_prefix}/:permalink" do
  set_common_variables
  @category = Category.find_by_permalink(params[:permalink])
  raise Sinatra::NotFound if @category.nil?
  @title = "#{@category.heading} - #{Nesta::Configuration.title}"
  @description = @category.description
  @keywords = @category.keywords
  cache haml(:category)
end
