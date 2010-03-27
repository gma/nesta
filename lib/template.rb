module Nesta
  module Template
    def self.local_view_path
      File.join(Nesta::Path.local, "views")
    end

    def self.theme_view_path
      if Nesta::Configuration.theme.nil?
        nil
      else
        File.join(Nesta::Path.themes, Nesta::Configuration.theme, "views")
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
