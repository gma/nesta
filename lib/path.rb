module Nesta
  class Path
    # We can't use Sinatra::Application.root as it's set to ./spec
    # while the tests are running.
    @root = File.dirname(File.dirname(__FILE__))

    class << self
      attr_accessor :root
    end

    def self.local(*args)
      path = args.empty? ? "local" : File.join("local", args)
      File.expand_path(path, root)
    end

    def self.themes(*args)
      path = args.empty? ? "themes" : File.join("themes", args)
      File.expand_path(path, root)
    end
  end
end
