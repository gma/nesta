require 'fileutils'

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
        %w[config.ru config/config.yml].each { |file| copy_template(file) }
        if @options.has_key?('heroku')
          copy_template('Gemfile') 
          copy_template('Rakefile') 
        end
      end
    end
  end
end
