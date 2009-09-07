require "yaml"

module Nesta
  class Configuration

    @@yaml = nil

    def self.cache
      get(environment)["cache"] || false
    end

    def self.title
      configuration["title"]
    end
    
    def self.subtitle
      configuration["subtitle"]
    end
    
    def self.description
      configuration["description"]
    end
    
    def self.keywords
      configuration["keywords"]
    end
    
    def self.author
      configuration["author"]
    end
    
    def self.page_path
      File.join(content_path, "pages")
    end
    
    def self.comment_path
      File.join(content_path, "comments")
    end
    
    def self.attachment_path
      File.join(content_path, "attachments")
    end
    
    def self.content_path
      get(environment)["content"]
    end
    
    def self.google_analytics_code
      get(environment)["google_analytics_code"]
    end
    
    def self.article_prefix
      get("prefixes")["article"] || "/articles"
    end
    
    def self.category_prefix
      get("prefixes")["category"] || ""
    end
    
    private
      def self.environment
        Sinatra::Application.environment.to_s
      end
    
      def self.configuration
        file = File.join(File.dirname(__FILE__), *%w[.. config config.yml])
        @@yaml ||= YAML::load(IO.read(file))
      end
      
      def self.get(key, default = {})
        configuration[key].nil? ? default : configuration[key]
      end
  end
end
