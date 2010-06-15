module Nesta
  class Path
    @local = "local"
    @themes = "themes"

    class << self
      attr_accessor :local, :themes
    end
  end
end
