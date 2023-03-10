require 'tilt'

module Nesta
  module View
    module Renderers
      def haml(template, options = {}, locals = {})
        defaults, engine = Nesta::View.render_options(template, :haml)
        super(template, defaults.merge(options), locals)
      end

      def erb(template, options = {}, locals = {})
        defaults, engine = Nesta::View.render_options(template, :erb)
        super(template, defaults.merge(options), locals)
      end

      def scss(template, options = {}, locals = {})
        Tilt.new(View::find_template(template, options, :scss)).render
      end

      def sass(template, options = {}, locals = {})
        Tilt.new(View::find_template(template, options, :sass)).render
      end

      def stylesheet(template, options = {}, locals = {})
        Tilt.new(View::find_template(template, options, :sass, :scss)).render
      end
    end

    def self.load_local_app
      app_file = Nesta::Path.local('app.rb')
      require app_file if File.exist?(app_file)
    end
    
    def self.load_theme_app
      if Nesta::Config.theme
        app_file = Nesta::Path.themes(Nesta::Config.theme, 'app.rb')
        require app_file if File.exist?(app_file)
      end
    end

    def self.find_template(template, options, *engines)
      defaults, engine = Nesta::View.render_options(template, *engines)
      views_path = defaults.merge(options)[:views]
      Nesta::View.template_path(engine, views_path, template)
    end

    private
      def self.template_path(engine, views, template)
        File.join(views, "#{template}.#{engine}")
      end

      def self.template_exists?(engine, views, template)
        views && File.exist?(template_path(engine, views, template))
      end

      def self.render_options(template, *engines)
        [local_view_path, theme_view_path, Nesta::App.views].each do |path|
          engines.each do |engine|
            if template_exists?(engine, path, template)
              return { views: path }, engine
            end
          end
        end
        [{}, :sass]
      end

      def self.local_view_path
        Nesta::Path.local("views")
      end
    
      def self.theme_view_path
        if Nesta::Config.theme.nil?
          nil
        else
          Nesta::Path.themes(Nesta::Config.theme, "views")
        end
      end
  end
end
