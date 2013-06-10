require 'sinatra/base'
require 'haml'
require 'sass'

require File.expand_path('../nesta', File.dirname(__FILE__))
require File.expand_path('env', File.dirname(__FILE__))
require File.expand_path('cache', File.dirname(__FILE__))
require File.expand_path('config', File.dirname(__FILE__))
require File.expand_path('models', File.dirname(__FILE__))
require File.expand_path('helpers', File.dirname(__FILE__))
require File.expand_path('navigation', File.dirname(__FILE__))
require File.expand_path('overrides', File.dirname(__FILE__))
require File.expand_path('path', File.dirname(__FILE__))

Encoding.default_external = 'utf-8' if RUBY_VERSION =~ /^1.9/

module Nesta
  class App < Sinatra::Base
    register Sinatra::Cache

    set :root, Nesta::Env.root
    set :views, File.expand_path('../../views', File.dirname(__FILE__))
    set :cache_enabled, Config.cache
    set :haml, { :format => :html5 }

    helpers Overrides::Renderers
    helpers Navigation::Renderers
    helpers View::Helpers

    before do
      if request.path_info =~ Regexp.new('./$')
        redirect to(request.path_info.sub(Regexp.new('/$'), '')) and return
      end
      cache_control :public, :must_revalidate, :max_age => 600 # 10 mins
    end

    not_found do
      set_common_variables
      haml(:not_found)
    end

    error do
      set_common_variables
      haml(:error)
    end unless Nesta::App.development?

    Overrides.load_local_app
    Overrides.load_theme_app

    get '/robots.txt' do
      content_type 'text/plain', :charset => 'utf-8'
      <<-EOF
# robots.txt
# See http://en.wikipedia.org/wiki/Robots_exclusion_standard
      EOF
    end

    if Config.handle_assets

      get '/css/:sheet.css' do
        content_type 'text/css', :charset => 'utf-8'
        cache stylesheet(params[:sheet].to_sym)
      end

      get %r{/attachments/([\w/.@-]+)} do |file|
        file = File.join(Nesta::Config.attachment_path, params[:captures].first)
        if file =~ /\.\.\//
          not_found
        else
          last_modified File.mtime(file)
          send_file(file, :disposition => nil)
        end
      end

    end

    get '/articles.xml' do
      content_type :xml, :charset => 'utf-8'
      set_from_config(:title, :subtitle, :author)
      @articles = Page.find_articles.select { |a| a.date && !a.draft? }[0..9]
      dates = @articles.map(&:date)
      last_updated = (dates.nil? || dates.empty?) ? Time.now : dates.max.xmlschema

      builder do |xml|
        xml.feed :xmlns => "http://www.w3.org/2005/Atom" do
          xml.title @title, :type=>'text'
          xml.subtitle @subtitle, :type=>'text'
          xml.generator "Nesta", :uri=>'http://nestacms.com'
          xml.id atom_id
          xml.link :href=>path_to('/articles.xml', true), :rel=>'self'
          xml.link :href=>path_to('/', true), :rel=>'alternate'
          xml.updated last_updated
          unless @author.nil? || @author.empty?
            xml.author do
              %w{name uri email}.each do |att|
                xml.tag!(att, @author[att]) if @author[att]
              end
            end
          end
          @articles.each do |article|
            xml.entry do
              xml.id atom_id(article)
              xml.title article.heading
              xml.updated article.date.xmlschema
              xml.published article.date.xmlschema
              xml.link :href => path_to(article.path, true), :rel => 'alternate'
              xml.summary article.summary, :type=>'html'
              xml.content absolute_urls(article.body(self)), :type=>'html'
              article.categories.each do |category|
                xml.category :term=>path_to(category.permalink), :label=>category.title
              end
            end
          end
        end
      end
    end

    get '/sitemap.xml' do
      content_type :xml, :charset => 'utf-8'
      @pages = Page.find_all.reject do |page|
        page.draft? or page.flagged_as?('skip-sitemap')
      end

      builder do |xml|
        xml.instruct! :xml, :version => "1.0", :encoding => 'utf-8'
        xml.urlset :xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9" do
          @pages.each do |page|
            xml.url do
              xml.loc path_to(page.path,true)
              xml.lastmod page.last_modified.xmlschema
              xml.changefreq "daily"
              xml.priority 1.0
            end
          end
        end
      end
    end

    get '*' do
      set_common_variables
      parts = params[:splat].map { |p| p.sub(/\/$/, '') }
      @page = Nesta::Page.find_by_path(File.join(parts))
      raise Sinatra::NotFound if @page.nil?
      last_modified @page.mtime
      @title = @page.title
      set_from_page(:description, :keywords)
      cache haml(@page.template, :layout => @page.layout)
    end
  end
end

Nesta::Plugin.load_local_plugins
Nesta::Plugin.initialize_plugins
