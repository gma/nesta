require File.expand_path('../command', File.dirname(__FILE__))

module Nesta
  module Commands
    module Theme
      class Enable
        include Command

        def initialize(*args)
          name = args.shift
          options = args.shift || {}
          name.nil? && (raise UsageError.new('name not specified'))
          @name = name
        end

        def execute
          update_config_yaml(/^\s*#?\s*theme:.*/, "theme: #{@name}")
        end
      end
    end
  end
end
