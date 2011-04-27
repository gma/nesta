require 'redcarpet'

module Nesta
  class Markdown < Redcarpet
    def initialize(text, *extensions)
      extensions += Nesta::Config.markdown_flags
      super(text, *extensions)
    end
  end
end
