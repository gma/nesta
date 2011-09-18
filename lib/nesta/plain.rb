require 'tilt/template'

module Tilt
  # Raw Htm (no template functionality). May eventually add syntax validation warnings
  class PlainHtmlTemplate < Template
    self.default_mime_type = 'text/html'

    def self.engine_initialized?
      true
    end

    def prepare
      @rawhtml = data
    end

    def evaluate(scope, locals, &block)
      @output ||= @rawhtml
    end
  end
  
  # Raw css (no template functionality). May eventually add syntax validation warnings
  class PlainCssTemplate < Template
    self.default_mime_type = 'text/css'

    def self.engine_initialized?
      true
    end

    def prepare
      @rawhtml = data
    end

    def evaluate(scope, locals, &block)
      @output ||= @rawhtml
    end
  end
end
