module Nesta
  module Overrides
    module Renderers
      def find_template(views, name, engine, &block)
        user_paths = [
          Nesta::Overrides.local_view_path,
          Nesta::Overrides.theme_view_path,
          views
        ].flatten.compact
        user_paths.each do |path|
          super(path, name, engine, &block)
        end
      end

      def stylesheet(template, options = {}, locals = {})
        scss(template, options, locals)
      rescue Errno::ENOENT
        sass(template, options, locals)
      end
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
  end
end
