require "yaml"

require "rubygems"
require "sinatra"

module Nesta
  class Config
    @yaml = nil

    @top_level_settings = %w[
          title subtitle description keywords theme disqus_short_name]
    @per_environment_settings = %w[cache content google_analytics_code]
    @settings = @per_environment_settings + @top_level_settings
        
    class << self
      attr_accessor :top_level_settings, :per_environment_settings, :settings
      attr_accessor :yaml
      
      Nesta::Config.per_environment_settings.each do |setting|
        define_method(setting) do
          ENV["NESTA_#{setting.upcase}"] || get(environment)[setting]
        end
      end
      
      Nesta::Config.top_level_settings.each do |setting|
        define_method(setting) do
          ENV["NESTA_#{setting.upcase}"] || configuration[setting]
        end
      end
    end
    
    def self.author
      environment_config = {}
      %w[name uri email].each do |setting|
        variable = "NESTA_AUTHOR__#{setting.upcase}"
        ENV[variable] && environment_config[setting] = ENV[variable]
      end
      environment_config.empty? ? configuration["author"] : environment_config
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
      def self.environment
        Sinatra::Application.environment.to_s
      end
    
      def self.configuration
        file = File.join(File.dirname(__FILE__), *%w[.. config config.yml])
        self.yaml ||= YAML::load(IO.read(file))
      end
      
      def self.get(key, default = {})
        configuration[key].nil? ? default : configuration[key]
      end
      
      def self.get_path(dirname, basename)
        basename.nil? ? dirname : File.join(dirname, basename)
      end
  end
end
