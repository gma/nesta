require File.expand_path('command', File.dirname(__FILE__))

module Nesta
  module Commands
    class New
      include Command

      def initialize(*args)
        path = args.shift
        options = args.shift || {}
        path.nil? && (raise UsageError.new('path not specified'))
        if File.exist?(path)
          raise RuntimeError.new("#{path} already exists") 
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

      def create_repository
        FileUtils.cd(@path) do
          File.open('.gitignore', 'w') do |file|
            file.puts %w[._* .*.swp .bundle .DS_Store .sass-cache].join("\n")
          end
          run_process('git', 'init')
          run_process('git', 'add', '.')
          run_process('git', 'commit', '-m', 'Initial commit')
        end
      end

      def execute
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
        copy_templates(templates)
        create_repository if @options['git']
      end
    end
  end
end
