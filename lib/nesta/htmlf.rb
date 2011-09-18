require 'tilt/template'

module Tilt
  # Raw Htm (no template functionality)
  class HtmlTemplate < Template
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
end
