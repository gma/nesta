require 'sinatra/base'
require 'haml'
require 'sass'

require File.expand_path('nesta', File.dirname(__FILE__))
require File.expand_path('cache', File.dirname(__FILE__))
require File.expand_path('config', File.dirname(__FILE__))
require File.expand_path('models', File.dirname(__FILE__))
require File.expand_path('navigation', File.dirname(__FILE__))
require File.expand_path('overrides', File.dirname(__FILE__))
require File.expand_path('path', File.dirname(__FILE__))
require File.expand_path('plugins', File.dirname(__FILE__))

Encoding.default_external = 'utf-8' if RUBY_VERSION =~ /^1.9/

Nesta::Plugins.load_local_plugins

module Nesta
  class App < Sinatra::Base
    register Sinatra::Cache

    set :views, File.expand_path('../../views', File.dirname(__FILE__))
    set :cache_enabled, Config.cache
    set :haml, { :format => :html5 }

    helpers Overrides::Renderers
    helpers Navigation::Renderers

    helpers do
      def set_from_config(*variables)
        variables.each do |var|
          instance_variable_set("@#{var}", Nesta::Config.send(var))
        end
      end
  
      def set_from_page(*variables)
        variables.each do |var|
          instance_variable_set("@#{var}", @page.send(var))
        end
      end
  
      def no_widow(text)
        text.split[0...-1].join(" ") + "&nbsp;#{text.split[-1]}"
      end
  
      def set_common_variables
        @menu_items = Nesta::Menu.for_path('/')
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
  
      def local_stylesheet?
        Nesta.deprecated('local_stylesheet?', 'use local_stylesheet_link_tag')
        File.exist?(File.expand_path('views/local.sass', Nesta::Env.root))
      end

      def local_stylesheet_link_tag(name)
        pattern = File.expand_path("views/#{name}.s{a,c}ss", Nesta::Env.root)
        if Dir.glob(pattern).size > 0
          haml_tag :link, :href => "/css/#{name}.css", :rel => "stylesheet"
        end
      end

      def latest_articles(count = 8)
        Nesta::Page.find_articles[0..count - 1]
      end

      def article_summaries(articles)
        haml(:summaries, :layout => false, :locals => { :pages => articles })
      end
    end

    not_found do
      set_common_variables
      haml(:not_found)
    end

    error do
      set_common_variables
      haml(:error)
    end unless Nesta::App.environment == :development

    Overrides.load_local_app
    Overrides.load_theme_app

    get '/robots.txt' do
      content_type 'text/plain', :charset => 'utf-8'
      <<-EOF
# robots.txt
# See http://en.wikipedia.org/wiki/Robots_exclusion_standard
      EOF
    end

    get '/css/:sheet.css' do
      content_type 'text/css', :charset => 'utf-8'
      cache stylesheet(params[:sheet].to_sym)
    end

    get %r{/attachments/([\w/.-]+)} do
      file = File.join(Nesta::Config.attachment_path, params[:captures].first)
      send_file(file, :disposition => nil)
    end

    get '/articles.xml' do
      content_type :xml, :charset => 'utf-8'
      set_from_config(:title, :subtitle, :author)
      @articles = Page.find_articles.select { |a| a.date }[0..9]
      cache haml(:atom, :format => :xhtml, :layout => false)
    end

    get '/sitemap.xml' do
      content_type :xml, :charset => 'utf-8'
      @pages = Page.find_all
      @last = @pages.map { |page| page.last_modified }.inject do |latest, page|
        (page > latest) ? page : latest
      end
      cache haml(:sitemap, :format => :xhtml, :layout => false)
    end

    get '*' do
      set_common_variables
      @heading = @title
      parts = params[:splat].map { |p| p.sub(/\/$/, '') }
      @page = Nesta::Page.find_by_path(File.join(parts))
      raise Sinatra::NotFound if @page.nil?
      @title = @page.title
      set_from_page(:description, :keywords)
      cache haml(@page.template, :layout => @page.layout)
    end
  end
end
