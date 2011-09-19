require 'erb'
require 'fileutils'

require File.expand_path('env', File.dirname(__FILE__))
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

    module Plugin
      class Create
        def initialize(name)
          name.nil? && (raise UsageError.new('name not specified'))
          @name = name
          @gem_name = "nesta-plugin-#{name}"
          if File.exist?(@gem_name)
            raise RuntimeError.new("#{@gem_name} already exists")
          end
        end

        def lib_path(*parts)
          File.join(@gem_name, 'lib', *parts)
        end

        def modify_required_file
          File.open(lib_path("#{@gem_name}.rb"), 'w') do |file|
            file.write <<-EOF
require "#{@gem_name}/version"

Nesta::Plugin.register(__FILE__)
            EOF
          end
        end

        def modify_init_file
          module_name = @name.split('-').map { |name| name.capitalize }.join('::')
          File.open(lib_path(@gem_name, 'init.rb'), 'w') do |file|
            file.puts <<-EOF
module Nesta
  module Plugin
    module #{module_name}
      module Helpers
        # If your plugin needs any helper methods, add them here...
      end
    end
  end

  class App
    helpers Nesta::Plugin::#{module_name}::Helpers
  end
end
            EOF
          end
        end

        def specify_gem_dependency
          gemspec = File.join(@gem_name, "#{@gem_name}.gemspec")
          File.open(gemspec, 'r+') do |file|
            output = ''
            file.each_line do |line|
              if line =~ /^end/
                output << '  s.add_dependency("nesta", ">= 0.9.11")' + "\n"
                output << '  s.add_development_dependency("rake")' + "\n"
              end
              output << line
            end
            file.pos = 0
            file.print(output)
            file.truncate(file.pos)
          end
        end

        def execute
          system('bundle', 'gem', @gem_name)
          modify_required_file
          modify_init_file
          specify_gem_dependency
          Dir.chdir(@gem_name) { system('git', 'add', '.') }
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
