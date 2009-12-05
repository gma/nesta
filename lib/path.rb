module Nesta
  class Path
    @@local = "local"
    @@themes = "themes"
    
    def self.local
      @@local
    end
    
    def self.local=(path)
      @@local = path
    end

    def self.themes
      @@themes
    end
    
    def self.themes=(path)
      @@themes = path
    end
  end
end
