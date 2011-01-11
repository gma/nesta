require "yaml"

require "rubygems"
require "sinatra"

module Nesta
  class Config
    @settings = %w[
      title subtitle theme disqus_short_name cache content google_analytics_code
    ]
    @author_settings = %w[name uri email]
    @yaml = nil
    
    class << self
      attr_accessor :settings, :author_settings, :yaml_conf
    end
    
    def self.method_missing(method, *args)
      setting = method.to_s
      if settings.include?(setting)
        from_environment(setting) || from_yaml(setting)
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
      environment_config.empty? ? from_yaml("author") : environment_config
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
    
    def self.from_environment(setting)
      value = ENV["NESTA_#{setting.upcase}"]
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

    def self.from_yaml(setting)
      if can_use_yaml?
        self.yaml_conf ||= YAML::load(IO.read(yaml_path))
        rack_env_conf = self.yaml_conf[Nesta::App.environment.to_s]
        (rack_env_conf && rack_env_conf[setting]) || self.yaml_conf[setting]
      end
    rescue Errno::ENOENT  # config file not found
      raise unless Nesta::App.environment == :test
      nil
    end
    private_class_method :from_yaml
    
    def self.get_path(dirname, basename)
      basename.nil? ? dirname : File.join(dirname, basename)
    end
    private_class_method :get_path
  end
end
