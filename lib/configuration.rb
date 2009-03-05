module Nesta
  class Configuration

    @@yaml = nil

    def self.cache
      environment_config["cache"] || false
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
    
    def self.article_path
      File.join(content_path, "articles")
    end
    
    def self.comment_path
      File.join(content_path, "comments")
    end
    
    def self.category_path
      File.join(content_path, "categories")
    end
    
    def self.attachment_path
      File.join(content_path, "attachments")
    end
    
    def self.content_path
      environment_config["content"]
    end
    
    def self.google_analytics_code
      environment_config["google_analytics_code"]
    end
    
    def self.environment_config
      configuration[environment] || {}
    end
    
    private
      def self.environment
        Sinatra::Application.environment.to_s
      end
    
      def self.configuration
        file = File.join(File.dirname(__FILE__), *%w[.. config config.yml])
        @@yaml ||= YAML::load(IO.read(file))
      end
  end
end
