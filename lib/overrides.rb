module Nesta
  module Overrides
    def self.load_local_app
      require File.join(Nesta::Path.local, "app")
    rescue LoadError
    end
    
    def self.local_view_path
      File.join(Nesta::Path.local, "views")
    end
    
    def self.load_theme_app
      require File.join(Nesta::Path.themes, Nesta::Config.theme, "app") unless Nesta::Config.theme.nil?
    rescue LoadError
    end

    def self.theme_view_path
      if Nesta::Config.theme.nil?
        nil
      else
        File.join(Nesta::Path.themes, Nesta::Config.theme, "views")
      end
    end

    def self.template_exists?(engine, views, template)
      views && File.exist?(File.join(views, "#{template}.#{engine}"))
    end

    def self.render_options(template, engine)
      if template_exists?(engine, local_view_path, template)
        { :views => local_view_path }
      elsif template_exists?(engine, theme_view_path, template)
        { :views => theme_view_path }
      else
        {}
      end
    end
  end
end
