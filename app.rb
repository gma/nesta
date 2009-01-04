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
  
  def url_for(page)
    base = page.is_a?(Article) ? base_url + "/articles" : base_url
    [base, page.permalink].join("/")
  end
  
  def base_url
    url = "http://#{request.host}"
    request.port == 80 ? url : url + ":#{request.port}"
  end  
  
  def nesta_atom_id_for_article(article)
    published = article.date.strftime('%Y-%m-%d')
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

configure :production do
  not_found do
    @home_link = Nesta::Configuration.title
    @google_analytics_code = Nesta::Configuration.google_analytics_code
    haml :not_found
  end

  error do
    @home_link = Nesta::Configuration.title
    @google_analytics_code = Nesta::Configuration.google_analytics_code
    haml :error
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

get "/attachments/:filename.:ext" do
  file = File.join(
      Nesta::Configuration.attachment_path, "#{params[:filename]}.#{params[:ext]}")
  send_file(file, :disposition => nil)
end

get "/articles.xml" do
  content_type :xml, :charset => "utf-8"
  @title = Nesta::Configuration.title
  @subtitle = Nesta::Configuration.subtitle
  @author = Nesta::Configuration.author
  @articles = Article.find_all.select { |a| a.date }[0..9]
  builder :atom
end

get "/sitemap.xml" do
  content_type :xml, :charset => "utf-8"
  @pages = Category.find_all + Article.find_all
  @last = @pages.map { |page| page.last_modified }.inject do |latest, this|
    this > latest ? this : latest
  end
  builder :sitemap
end
