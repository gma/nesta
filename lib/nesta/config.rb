require 'singleton'
require 'yaml'

require_relative './config_file'

module Nesta
  class Config
    include Singleton

    class NotDefined < KeyError; end

    SETTINGS = %w[
      author
      build
      content
      disqus_short_name
      domain
      google_analytics_code
      read_more
      subtitle
      theme
      title
    ]

    class << self
      extend Forwardable
      def_delegators *[:instance, :fetch].concat(SETTINGS.map(&:to_sym))
    end

    attr_accessor :config

    def fetch(setting, *default)
      setting = setting.to_s
      self.config ||= read_config_file(setting)
      env_config = config.fetch(Nesta::App.environment.to_s, {})
      env_config.fetch(setting) do
        config.fetch(setting) do
          raise NotDefined.new(setting)
        end
      end
    rescue NotDefined
      default.empty? && raise || (return default.first)
    end

    def method_missing(method, *args)
      if SETTINGS.include?(method.to_s)
        fetch(method.to_s, nil)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      SETTINGS.include?(method.to_s) || super
    end

    def build
      fetch('build', {})
    end

    def read_more
      fetch('read_more', 'Continue reading')
    end

    private

    def read_config_file(setting)
      YAML::load(ERB.new(IO.read(Nesta::ConfigFile.path)).result)
    rescue Errno::ENOENT
      raise NotDefined.new(setting)
    end

    def self.get_path(dirname, basename)
      basename.nil? ? dirname : File.join(dirname, basename)
    end
    private_class_method :get_path

    def self.content_path(basename = nil)
      get_path(content, basename)
    end

    def self.page_path(basename = nil)
      get_path(File.join(content_path, "pages"), basename)
    end

    def self.attachment_path(basename = nil)
      get_path(File.join(content_path, "attachments"), basename)
    end
  end
end
