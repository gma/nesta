module Nesta
  module Commands
    module Theme
      class Create
        def initialize(*args)
          name = args.shift
          options = args.shift || {}
          name.nil? && (raise UsageError.new('name not specified'))
          @name = name
          @theme_path = Nesta::Path.themes(@name)
          if File.exist?(@theme_path)
            Nesta::Process.new.fail("Error: #{@theme_path} already exists")
          end
        end

        def make_directories
          FileUtils.mkdir_p(File.join(@theme_path, 'public', @name))
          FileUtils.mkdir_p(File.join(@theme_path, 'views'))
        end

        def execute(process)
          make_directories
          {
            'themes/README.md' => "#{@theme_path}/README.md",
            'themes/app.rb' => "#{@theme_path}/app.rb",
            'themes/views/layout.haml' => "#{@theme_path}/views/layout.haml",
            'themes/views/page.haml' => "#{@theme_path}/views/page.haml",
            'themes/views/master.sass' => "#{@theme_path}/views/master.sass"
          }.each do |src, dest|
            Nesta::Commands::Template.new(src).copy_to(dest, binding)
          end
        end
      end
    end
  end
end
