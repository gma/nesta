require File.expand_path('../command', File.dirname(__FILE__))

module Nesta
  module Commands
    module Theme
      class Create
        include Command

        def initialize(*args)
          name = args.shift
          options = args.shift || {}
          name.nil? && (raise UsageError.new('name not specified'))
          @name = name
          @theme_path = Nesta::Path.themes(@name)
          fail("#{@theme_path} already exists") if File.exist?(@theme_path)
        end

        def make_directories
          FileUtils.mkdir_p(File.join(@theme_path, 'public', @name))
          FileUtils.mkdir_p(File.join(@theme_path, 'views'))
        end

        def execute
          make_directories
          copy_templates(
            'themes/README.md' => "#{@theme_path}/README.md",
            'themes/app.rb' => "#{@theme_path}/app.rb",
            'themes/views/layout.haml' => "#{@theme_path}/views/layout.haml",
            'themes/views/page.haml' => "#{@theme_path}/views/page.haml",
            'themes/views/master.sass' => "#{@theme_path}/views/master.sass"
          )
        end
      end
    end
  end
end
