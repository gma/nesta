module Nesta
  module Overrides
    module Renderers

      def haml(template, options = {}, locals = {})
        defaults, engine = Overrides.render_options(template, :haml)
        super(template, defaults.merge(options), locals)
      end

      def scss(template, options = {}, locals = {}, full_path = false)
        options = Overrides.merge_options(template, :scss, options, full_path)
        super(template, options, locals)
      end

      def sass(template, options = {}, locals = {}, full_path = false)
        options = Overrides.merge_options(template, :sass, options, full_path)
        super(template, options, locals)
      end

      def stylesheet(template, options = {}, locals = {})
        defaults, engine = Overrides.render_options(template, :sass, :scss)
        engine_invoke = engine == :sass ? method(:sass) : method(:scss)
        engine_invoke.call(template, defaults.merge(options), locals, true)
      end

    end

    def self.load_local_app
      require Nesta::Path.local("app")
    rescue LoadError
    end
    
    def self.load_theme_app
      if Nesta::Config.theme
        require Nesta::Path.themes(Nesta::Config.theme, "app")
      end
    rescue LoadError
    end

    private
      def self.template_exists?(engine, views, template)
        views && File.exist?(File.join(views, "#{template}.#{engine}"))
      end

      def self.render_options(template, *engines)
        [local_view_path, theme_view_path].each do |path|
          engines.each do |engine|
            if template_exists?(engine, path, template)
              return { :views => path}, engine
            end
          end
        end
        return {}, nil
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

      def self.merge_options(template, engine, options, full_path)
        unless full_path
          defaults, engine = Overrides.render_options(template, engine)
          defaults.merge(options)
        else
          options
        end
      end
  end
end
