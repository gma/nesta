module Nesta
  module Commands
    class New
      def initialize(*args)
        path = args.shift
        options = args.shift || {}
        path.nil? && (raise UsageError, 'path not specified')
        if File.exist?(path)
          raise "#{path} already exists"
        end
        @path = path
        @options = options
      end

      def make_directories
        %w[content/attachments content/pages].each do |dir|
          FileUtils.mkdir_p(File.join(@path, dir))
        end
      end

      def have_rake_tasks?
        @options['vlad']
      end

      def create_repository(process)
        FileUtils.cd(@path) do
          File.open('.gitignore', 'w') do |file|
            lines = %w[._* .*.swp .bundle .DS_Store .sass-cache dist]
            file.puts lines.join("\n")
          end
          process.run('git', 'init')
          process.run('git', 'add', '.')
          process.run('git', 'commit', '-m', 'Initial commit')
        end
      end

      def execute(process)
        make_directories
        templates = {
          'config.ru' => "#{@path}/config.ru",
          'config/config.yml' => "#{@path}/config/config.yml",
          'index.haml' => "#{@path}/content/pages/index.haml",
          'Gemfile' => "#{@path}/Gemfile"
        }
        templates['Rakefile'] = "#{@path}/Rakefile" if have_rake_tasks?
        if @options['vlad']
          templates['config/deploy.rb'] = "#{@path}/config/deploy.rb"
        end
        templates.each do |src, dest|
          Nesta::Commands::Template.new(src).copy_to(dest, binding)
        end
        create_repository(process) if @options['git']
      end
    end
  end
end
