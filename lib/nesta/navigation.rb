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
        if item.respond_to?(:each)
          if (options[:levels] - 1) > 0
            haml_tag :li do
              display_menu(item, :levels => (options[:levels] - 1))
            end
          end
        else
          html_class = (request.path == item.abspath) ? "current" : nil
          haml_tag :li, :class => html_class do
            haml_tag :a, :<, :href => item.abspath do
              haml_concat item.heading
            end
          end
        end
      end

      def breadcrumb_ancestors
        ancestors = []
        page = @page
        while page
          ancestors << page
          page = page.parent
        end
        ancestors.reverse
      end

      def display_breadcrumbs(options = {})
        haml_tag :ul, :class => options[:class] do
          breadcrumb_ancestors[0...-1].each do |page|
            haml_tag :li do
              haml_tag :a, :<, :href => page.abspath do
                haml_concat breadcrumb_label(page)
              end
            end
          end
          haml_tag(:li) { haml_concat breadcrumb_label(@page) }
        end
      end

      def breadcrumb_label(page)
        (page.abspath == '/') ? 'Home' : page.heading
      end
    end
  end
end
