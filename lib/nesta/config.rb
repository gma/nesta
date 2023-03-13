require 'yaml'

module Nesta
  class Config
    class NotDefined < KeyError; end

    @settings = %w[
      content
      disqus_short_name
      google_analytics_code
      read_more
      subtitle
      theme
      title
    ]
    @author_settings = %w[name uri email]
    
    class << self
      attr_accessor :settings, :author_settings, :config
    end

    def self.fetch(setting, *default)
      setting = setting.to_s
      self.config ||= self.read_config_file(setting)
      env_config = self.config.fetch(Nesta::App.environment.to_s, {})
      env_config.fetch(
        setting,
        self.config.fetch(setting) { raise NotDefined.new(setting) }
      )
    rescue NotDefined
      default.empty? && raise || (return default.first)
    end

    def self.method_missing(method, *args)
      if settings.include?(method.to_s)
        fetch(method, nil)
      else
        super
      end
    end

    def self.author
      fetch('author', nil)
    end

    def self.read_more
      fetch('read_more', 'Continue reading')
    end

    def self.yaml_path
      File.expand_path('config/config.yml', Nesta::App.root)
    end

    def self.read_config_file(setting)
      self.config ||= YAML::load(ERB.new(IO.read(yaml_path)).result)
    rescue Errno::ENOENT
      raise NotDefined.new(setting)
    end
    private_class_method :read_config_file

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
