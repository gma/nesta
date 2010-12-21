module Nesta
  module Navigation
    module Renderers
      def display_menu(menu, options = {})
        defaults = { :class => nil, :levels => 2 }
        options = defaults.merge(options)
        if options[:levels] > 0
          haml_tag :ul, :class => options[:class] do
            menu.each do |item|
              display_menu_item(item, options)
            end
          end
        end
      end

      def display_menu_item(item, options = {})
        haml_tag :li do
          if item.respond_to?(:each)
            display_menu(item, :levels => (options[:levels] - 1))
          else
            haml_tag :a, :href => item.abspath do
              haml_concat item.heading
            end
          end
        end
      end
    end
  end
end
