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

      def copy_template(src, dest)
        root = File.expand_path('../../templates', File.dirname(__FILE__))
        FileUtils.mkdir_p(File.dirname(dest))
        template = ERB.new(File.read(File.join(root, src)))
        File.open(dest, 'w') { |file| file.puts template.result(binding) }
      end

      def copy_templates(templates)
        templates.each { |src, dest| copy_template(src, dest) }
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

      def execute
        make_directories
        templates = {
          'config.ru' => "#{@path}/config.ru",
          'config/config.yml' => "#{@path}/config/config.yml",
          'Gemfile' => "#{@path}/Gemfile"
        }
        templates['Rakefile'] = "#{@path}/Rakefile" if @options['heroku']
        copy_templates(templates)
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
          theme_config = /^\s*#?\s*theme:.*/
          configured = false
          File.open(Nesta::Config.yaml_path, 'r+') do |file|
            output = ''
            file.each_line do |line|
              output << line.sub(theme_config, "theme: #{@name}")
              configured = true if line =~ theme_config
            end
            output << "theme: #{@name}\n" unless configured
            file.pos = 0
            file.print(output)
            file.truncate(file.pos)
          end
        end
      end
    end
  end
end
