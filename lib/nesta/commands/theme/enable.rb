require File.expand_path('../../config_file', File.dirname(__FILE__))

module Nesta
  module Commands
    module Theme
      class Enable
        def initialize(*args)
          name = args.shift
          name.nil? && (raise UsageError, 'name not specified')
          @name = name
        end

        def execute(process)
          Nesta::ConfigFile.new.set_value('theme', @name)
        end
      end
    end
  end
end
