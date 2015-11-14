module Nesta
  module Plugin
    module Test
      module Helpers
        # If your plugin needs any helper methods, add them here...
      end
    end
  end

  class App
    helpers Nesta::Plugin::Test::Helpers
  end

  class Page
    def self.method_added_by_plugin
    end
  end
end
