module Nesta
  class Configuration

    def self.title
      configuration["blog"]["title"]
    end
    
    def self.subheading
      configuration["blog"]["subheading"]
    end
    
    def self.article_path
      configuration["content"] + "/articles"
    end
    
    def self.category_path
      configuration["content"] + "/categories"
    end
    
    def self.google_analytics_code
      configuration["google_analytics_code"]
    end
    
    private
      def self.configuration
        file = File.join(File.dirname(__FILE__), *%w[.. config config.yml])
        YAML::load(IO.read(file))
      end
  end
end
