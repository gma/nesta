# Use the app.rb file to load Ruby code, modify or extend the models, or
# do whatever else you fancy when the theme is loaded.

module Nesta
  class App
    # Uncomment the Rack::Static line below if your theme has assets
    # (i.e images or JavaScript).
    #
    # Put your assets in themes/<%= @name %>/public/<%= @name %>.
    #
    # use Rack::Static, urls: ["/<%= @name %>"], root: "themes/<%= @name %>/public"

    helpers do
      # Add new helpers here.
    end

    # Add new routes here.
  end
end
