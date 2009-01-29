module Nesta
  class Configuration

    @@yaml = nil

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
      configuration[environment]["content"]
    end
    
    def self.google_analytics_code
      configuration[environment]["google_analytics_code"]
    end
    
    private
      def self.environment
        ENV["RACK_ENV"] || "development"
      end
    
      def self.configuration
        file = File.join(File.dirname(__FILE__), *%w[.. config config.yml])
        @@yaml ||= YAML::load(IO.read(file))
      end
  end
end
