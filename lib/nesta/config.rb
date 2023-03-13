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
    @yaml = nil
    
    class << self
      attr_accessor :settings, :author_settings, :yaml_conf
    end

    def self.fetch(key, *default)
      from_yaml(key.to_s)
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
      from_yaml('author')
    rescue NotDefined
      nil
    end

    def self.content_path(basename = nil)
      get_path(content, basename)
    end
    
    def self.page_path(basename = nil)
      get_path(File.join(content_path, "pages"), basename)
    end
    
    def self.attachment_path(basename = nil)
      get_path(File.join(content_path, "attachments"), basename)
    end
    
    def self.yaml_path
      File.expand_path('config/config.yml', Nesta::App.root)
    end

    def self.read_more
      fetch('read_more', 'Continue reading')
    end

    def self.yaml_exists?
      File.exist?(yaml_path)
    end
    private_class_method :yaml_exists?

    def self.from_hash(hash, setting)
      hash.fetch(setting) { raise NotDefined.new(setting) }
    end
    private_class_method :from_hash

    def self.from_yaml(setting)
      raise NotDefined.new(setting) unless yaml_exists?
      self.yaml_conf ||= YAML::load(ERB.new(IO.read(yaml_path)).result)
      env_config = self.yaml_conf.fetch(Nesta::App.environment.to_s, {})
      begin
        from_hash(env_config, setting)
      rescue NotDefined
        from_hash(self.yaml_conf, setting)
      end
    end
    private_class_method :from_yaml
    
    def self.get_path(dirname, basename)
      basename.nil? ? dirname : File.join(dirname, basename)
    end
    private_class_method :get_path
  end
end
