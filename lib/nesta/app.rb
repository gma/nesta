require 'sinatra/base'
require 'haml'
require 'sassc'

require File.expand_path('../nesta', File.dirname(__FILE__))
require File.expand_path('env', File.dirname(__FILE__))
require File.expand_path('config', File.dirname(__FILE__))
require File.expand_path('models', File.dirname(__FILE__))
require File.expand_path('helpers', File.dirname(__FILE__))
require File.expand_path('navigation', File.dirname(__FILE__))
require File.expand_path('overrides', File.dirname(__FILE__))
require File.expand_path('path', File.dirname(__FILE__))

Encoding.default_external = 'utf-8' if RUBY_VERSION =~ /^1.9/

module Nesta
  class App < Sinatra::Base
    set :root, Nesta::Env.root
    set :views, File.expand_path('../../views', File.dirname(__FILE__))
    set :haml, { format: :html5 }

    helpers Overrides::Renderers
    helpers Navigation::Renderers
    helpers View::Helpers

    before do
      if request.path_info =~ Regexp.new('./$')
        redirect to(request.path_info.sub(Regexp.new('/$'), ''))
      end
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
      content_type 'text/plain', charset: 'utf-8'
      <<-EOF
# robots.txt
# See http://en.wikipedia.org/wiki/Robots_exclusion_standard
      EOF
    end

    get '/css/:sheet.css' do
      content_type 'text/css', charset: 'utf-8'
      stylesheet(params[:sheet].to_sym)
    end

    get '/attachments/*' do |path|
      filename = File.join(Nesta::Config.attachment_path, path)
      send_file(filename, disposition: nil)
    end

    get '/articles.xml' do
      content_type :xml, charset: 'utf-8'
      set_from_config(:title, :subtitle, :author)
      @articles = Page.find_articles.select { |a| a.date }[0..9]
      haml(:atom, format: :xhtml, layout: false)
    end

    get '/sitemap.xml' do
      content_type :xml, charset: 'utf-8'
      @pages = Page.find_all.reject do |page|
        page.draft? or page.flagged_as?('skip-sitemap')
      end
      @last = @pages.map { |page| page.last_modified }.inject do |latest, page|
        (page > latest) ? page : latest
      end
      haml(:sitemap, format: :xhtml, layout: false)
    end

    get '*' do
      set_common_variables
      parts = params[:splat].map { |p| p.sub(/\/$/, '') }
      @page = Nesta::Page.find_by_path(File.join(parts))
      raise Sinatra::NotFound if @page.nil?
      @title = @page.title
      set_from_page(:description, :keywords)
      haml(@page.template, layout: @page.layout)
    end
  end
end

Nesta::Plugin.load_local_plugins
Nesta::Plugin.initialize_plugins
