require 'yaml'

module Nesta
  class Config
    class NotDefined < KeyError; end

    @settings = %w[
      cache
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
      from_environment(key.to_s)
    rescue NotDefined
      begin
        from_yaml(key.to_s)
      rescue NotDefined
        default.empty? && raise || (return default.first)
      end
    end

    def self.method_missing(method, *args)
      if settings.include?(method.to_s)
        fetch(method, nil)
      else
        super
      end
    end
    
    def self.author
      environment_config = {}
      %w[name uri email].each do |setting|
        variable = "NESTA_AUTHOR__#{setting.upcase}"
        ENV[variable] && environment_config[setting] = ENV[variable]
      end
      environment_config.empty? ? from_yaml('author') : environment_config
    rescue NotDefined
      nil
    end

    def self.cache
      Nesta.deprecated('Nesta::Config.cache',
                       'see http://nestacms.com/docs/deployment/page-caching')
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

    def self.from_environment(setting)
      value = ENV.fetch("NESTA_#{setting.upcase}")
    rescue KeyError
      raise NotDefined.new(setting)
    else
      overrides = { "true" => true, "false" => false }
      overrides.has_key?(value) ? overrides[value] : value
    end
    private_class_method :from_environment
    
    def self.yaml_exists?
      File.exist?(yaml_path)
    end
    private_class_method :yaml_exists?

    def self.can_use_yaml?
      ENV.keys.grep(/^NESTA/).empty? && yaml_exists?
    end
    private_class_method :can_use_yaml?

    def self.from_hash(hash, setting)
      hash.fetch(setting) { raise NotDefined.new(setting) }
    end
    private_class_method :from_hash

    def self.from_yaml(setting)
      raise NotDefined.new(setting) unless can_use_yaml?
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
