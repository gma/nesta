require 'erb'
require 'fileutils'

require File.expand_path('version', File.dirname(__FILE__))

module Nesta
  module Commands
    class UsageError < RuntimeError; end

    module Command
      def fail(message)
        $stderr.puts "Error: #{message}"
        exit 1
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

      def create
        make_directories
        copy_templates
      end

      def make_directories
        %w[content/attachments content/pages].each do |dir|
          FileUtils.mkdir_p(File.join(@path, dir))
        end
      end

      def copy_template(file)
        root = File.expand_path('../../templates', File.dirname(__FILE__))
        FileUtils.mkdir_p(File.dirname(File.join(@path, file)))
        template = ERB.new(File.read(File.join(root, file)))
        File.open(File.join(@path, file), 'w') do |file|
          file.puts template.result(binding)
        end
      end

      def copy_templates
        %w[
          config.ru
          config/config.yml
          Gemfile
        ].each { |file| copy_template(file) }
        if @options.has_key?('heroku')
          copy_template('Rakefile') 
        end
      end
    end

    class Theme
      include Command

      def install(url, options = {})
        url.nil? && (raise UsageError.new('URL not specified'))
        name = File.basename(url, '.git').sub(/nesta-theme-/, '')
        system('git', 'clone', url, "themes/#{name}")
        FileUtils.rm_r(File.join("themes/#{name}", '.git'))
        enable(name)
      end

      def enable(name, options = {})
      end
    end
  end
end
