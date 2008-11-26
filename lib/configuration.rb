module Nesta
  class Configuration

    def self.title
      configuration["blog"]["title"]
    end
    
    def self.subheading
      configuration["blog"]["subheading"]
    end
    
    private
      def self.configuration
        file = File.join(File.dirname(__FILE__), *%w[.. config config.yml])
        YAML::load(IO.read(file))
      end
  end
end
