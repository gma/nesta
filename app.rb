require "rubygems"
require "sinatra"
require "builder"
require "haml"
require "sass"

require "lib/cache"
require "lib/config"
require "lib/models"
require "lib/path"
require "lib/overrides"

set :cache_enabled, Nesta::Config.cache

helpers do
  def set_from_config(*variables)
    variables.each do |var|
      instance_variable_set("@#{var}", Nesta::Config.send(var))
    end
  end
  
  def set_from_page(*variables)
    variables.each { |var| instance_variable_set("@#{var}", @page.send(var)) }
  end
  
  def set_title(page)
    if page.respond_to?(:parent) && page.parent
      @title = "#{page.heading} - #{page.parent.heading}"
    else
      @title = "#{page.heading} - #{Nesta::Config.title}"
    end
  end
  
  def no_widow(text)
    text.split[0...-1].join(" ") + "&nbsp;#{text.split[-1]}"
  end
  
  def set_common_variables
    @menu_items = Page.menu_items
    @site_title = Nesta::Config.title
    set_from_config(:title, :subtitle, :google_analytics_code)
    @heading = @title
  end

  def url_for(page)
    File.join(base_url, page.path)
  end
  
  def base_url
    url = "http://#{request.host}"
    request.port == 80 ? url : url + ":#{request.port}"
  end
  
  def absolute_urls(text)
    text.gsub!(/(<a href=['"])\//, '\1' + base_url + '/')
    text
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
  
  def haml(template, options = {}, locals = {})
    render_options = Nesta::Overrides.render_options(template, :haml)
    super(template, render_options.merge(options), locals)
  end
  
  def sass(template, options = {}, locals = {})
    render_options = Nesta::Overrides.render_options(template, :sass)
    super(template, render_options.merge(options), locals)
  end
  
  def local_stylesheet?
    # Checks for the existence of local/views/local.sass. Useful for themes
    # that want to give the user the option to add their own CSS rules.
    File.exist?(File.join(File.dirname(__FILE__), *%w[local views local.sass]))
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

# If you want to change Nesta's behaviour, you have two options:
#
# 1. Edit the code. You can merge in future upstream changes with git.
# 2. Add code to local/app.rb that overrides the default behaviour,
#    leaving the default files untouched (no "tricky" merging required).
#
# Neither way is necessarily *better* than the other; it's up to you to
# choose the most appropriate course of action for your site. Merging future
# changes in will typically be a straightforward task, but you may find
# the ./local directory to be an easy way to manage more significant
# changes to Nesta's behaviour that are likely to conflict with future
# changes to the main code base.
#
# Note that you can modify the behaviour of any of the default actions
# (defined below) in local/app.rb, or replace any of the default view
# templates by creating replacements of the same name in local/views.
#

Nesta::Overrides.load_theme_app
Nesta::Overrides.load_local_app

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

get %r{/attachments/([\w/.-]+)} do
  file = File.join(
      Nesta::Config.attachment_path, params[:captures].first)
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
  @last = @pages.map { |page| page.last_modified }.inject do |latest, page|
    (page > latest) ? page : latest
  end
  cache builder(:sitemap)
end

get "*" do
  set_common_variables
  parts = params[:splat].map { |p| p.sub(/\/$/, "") }
  @page = Page.find_by_path(File.join(parts))
  raise Sinatra::NotFound if @page.nil?
  set_title(@page)
  set_from_page(:description, :keywords)
  cache haml(:page)
end
