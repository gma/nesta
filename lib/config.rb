require "yaml"

require "rubygems"
require "sinatra"

module Nesta
  class Config
    @settings = %w[
      title subtitle description keywords theme disqus_short_name
      cache content google_analytics_code
    ]
    @yaml = nil
    
    class << self
      attr_accessor :settings
      attr_accessor :yaml_conf
    end
    
    def self.method_missing(method, *args)
      setting = method.to_s
      if settings.include?(setting)
        ENV["NESTA_#{setting.upcase}"] || from_yaml(setting)
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
    
    private
      def self.can_use_yaml?
        ENV.keys.grep(/^NESTA/).empty?
      end
      
      def self.from_yaml(setting)
        return nil unless can_use_yaml?
        if self.yaml_conf.nil?
          file = File.join(File.dirname(__FILE__), *%w[.. config config.yml])
          self.yaml_conf = YAML::load(IO.read(file))
        end
        rack_env_conf = self.yaml_conf[Sinatra::Application.environment.to_s]
        (rack_env_conf && rack_env_conf[setting]) || self.yaml_conf[setting]
      end
      
      def self.get_path(dirname, basename)
        basename.nil? ? dirname : File.join(dirname, basename)
      end
  end
end
