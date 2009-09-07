require "rubygems"
require "sinatra"
require "builder"
require "haml"
require "sass"

require "lib/cache"
require "lib/configuration"
require "lib/models"

set :cache_enabled, Nesta::Configuration.cache

helpers do
  def set_from_config(*variables)
    variables.each do |var|
      instance_variable_set("@#{var}", Nesta::Configuration.send(var))
    end
  end
  
  def set_from_page(*variables)
    variables.each { |var| instance_variable_set("@#{var}", @page.send(var)) }
  end
  
  def set_title(page)
    if page.respond_to?(:parent) && page.parent
      @title = "#{page.heading} - #{page.parent.heading}"
    else
      @title = "#{page.heading} - #{Nesta::Configuration.title}"
    end
  end
  
  def set_common_variables
    @categories = Page.find_all
    @site_title = Nesta::Configuration.title
    set_from_config(:google_analytics_code)
  end

  def url_for(page)
    File.join(base_url, page.path)
  end
  
  def base_url
    url = "http://#{request.host}"
    request.port == 80 ? url : url + ":#{request.port}"
  end  
  
  def nesta_atom_id_for_page(page)
    published = page.date.strftime('%Y-%m-%d')
    "tag:#{request.host},#{published}:#{page.abspath}"
  end
  
  def atom_id(page = nil)
    if page
      page.atom_id || nesta_atom_id_for_page(page)
    else
      "tag:#{request.host},2009:/"
    end
  end
  
  def format_date(date)
    date.strftime("%d %B %Y")
  end
end

not_found do
  set_common_variables
  haml(:not_found)
end

error do
  set_common_variables
  haml(:error)
end unless Sinatra::Application.environment == :development

get "/css/:sheet.css" do
  content_type "text/css", :charset => "utf-8"
  cache sass(params[:sheet].to_sym)
end

get "/" do
  set_common_variables
  set_from_config(:title, :subtitle, :description, :keywords)
  @heading = @title
  @title = "#{@title} - #{@subtitle}"
  @articles = Page.find_articles[0..7]
  @body_class = "home"
  cache haml(:index)
end

get "/attachments/:filename.:ext" do
  file = File.join(
      Nesta::Configuration.attachment_path, "#{params[:filename]}.#{params[:ext]}")
  send_file(file, :disposition => nil)
end

get "/articles.xml" do
  content_type :xml, :charset => "utf-8"
  set_from_config(:title, :subtitle, :author)
  @articles = Page.find_articles.select { |a| a.date }[0..9]
  cache builder(:atom)
end

get "/sitemap.xml" do
  content_type :xml, :charset => "utf-8"
  @pages = Page.find_all
  @last = @pages.map { |page| page.last_modified }.inject do |latest, this|
    this > latest ? this : latest
  end
  cache builder(:sitemap)
end

get "*" do
  set_common_variables
  @page = Page.find_by_path(File.join(params[:splat]))
  raise Sinatra::NotFound if @page.nil?
  set_title(@page)
  set_from_page(:description, :keywords, :comments)
  cache haml(:page)
end
