module Nesta
  class Path
    def self.local(*args)
      File.expand_path(File.join(args), Nesta::App.root)
    end

    def self.themes(*args)
      File.expand_path(File.join('themes', *args), Nesta::App.root)
    end
  end
end
