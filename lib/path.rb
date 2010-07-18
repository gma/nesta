module Nesta
  class Path
    @local = File.join(File.dirname(__FILE__), *%w[.. local])
    @themes = File.join(File.dirname(__FILE__), *%w[.. themes])

    class << self
      attr_accessor :local, :themes
    end
  end
end
