module Nesta
  module Plugin
    module <%= module_name %>
      module Helpers
        # If your plugin needs any helper methods, add them here...
      end
    end
  end

  class App
    helpers Nesta::Plugin::<%= module_name %>::Helpers
  end
end
