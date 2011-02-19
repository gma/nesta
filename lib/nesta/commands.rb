require 'erb'
require 'fileutils'

require File.expand_path('app', File.dirname(__FILE__))
require File.expand_path('path', File.dirname(__FILE__))
require File.expand_path('version', File.dirname(__FILE__))

module Nesta
  module Commands
    class UsageError < RuntimeError; end

    module Command
      def fail(message)
        $stderr.puts "Error: #{message}"
        exit 1
      end

      def template_root
        File.expand_path('../../templates', File.dirname(__FILE__))
      end

      def copy_template(src, dest)
        FileUtils.mkdir_p(File.dirname(dest))
        template = ERB.new(File.read(File.join(template_root, src)))
        File.open(dest, 'w') { |file| file.puts template.result(binding) }
      end

      def copy_templates(templates)
        templates.each { |src, dest| copy_template(src, dest) }
      end

      def update_config_yaml(pattern, replacement)
        configured = false
        File.open(Nesta::Config.yaml_path, 'r+') do |file|
          output = ''
          file.each_line do |line|
            if configured
              output << line
            else
              output << line.sub(pattern, replacement)
              configured = true if line =~ pattern
            end
          end
          output << "#{replacement}\n" unless configured
          file.pos = 0
          file.print(output)
          file.truncate(file.pos)
        end
      end
    end

    class New
      include Command

      def initialize(path, options = {})
        path.nil? && (raise UsageError.new('path not specified'))
        fail("#{path} already exists") if File.exist?(path)
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
          system('git', 'init')
          system('git', 'add', '.')
          system('git', 'commit', '-m', 'Initial commit')
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

    module Demo
      class Content
        include Command

        def initialize
          @dir = 'content-demo'
        end

        def clone_or_update_repository
          repository = 'git://github.com/gma/nesta-demo-content.git'
          path = Nesta::Path.local(@dir)
          if File.exist?(path)
            FileUtils.cd(path) { system('git', 'pull', 'origin', 'master') }
          else
            system('git', 'clone', repository, path)
          end
        end

        def configure_git_to_ignore_repo
          excludes = Nesta::Path.local('.git/info/exclude')
          if File.exist?(excludes) && File.read(excludes).scan(@dir).empty?
            File.open(excludes, 'a') { |file| file.puts @dir }
          end
        end

        def execute
          clone_or_update_repository
          configure_git_to_ignore_repo
          update_config_yaml(/^\s*#?\s*content:.*/, "content: #{@dir}")
        end
      end
    end

    module Theme
      class Create
        include Command

        def initialize(name, options = {})
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
            'themes/app.rb' => "#{@theme_path}/app.rb"
          )
        end
      end

      class Install
        include Command

        def initialize(url, options = {})
          url.nil? && (raise UsageError.new('URL not specified'))
          @url = url
          @name = File.basename(url, '.git').sub(/nesta-theme-/, '')
        end

        def execute
          system('git', 'clone', @url, "themes/#{@name}")
          FileUtils.rm_r(File.join("themes/#{@name}", '.git'))
          enable(@name)
        end
      end

      class Enable
        include Command

        def initialize(name, options = {})
          name.nil? && (raise UsageError.new('name not specified'))
          @name = name
        end

        def execute
          update_config_yaml(/^\s*#?\s*theme:.*/, "theme: #{@name}")
        end
      end
    end
  end
end
