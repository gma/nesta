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
          html_class = current_item?(item) ? current_menu_item_class : nil
          haml_tag :li, :class => html_class do
            haml_tag :a, :<, :href => path_to(item.abspath) do
              haml_concat link_text(item)
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
              haml_tag :a, :<, :href => path_to(page.abspath), :itemprop => 'url' do
                haml_tag :span, :<, :itemprop => 'title' do
                  haml_concat link_text(page)
                end
              end
            end
          end
          haml_tag(:li, :class => current_breadcrumb_class) do
            haml_concat link_text(@page)
          end
        end
      end

      def link_text(page)
        page.link_text
      rescue LinkTextNotSet
        return 'Home' if page.abspath == '/'
        raise
      end

      def breadcrumb_label(page)
        Nesta.deprecated('breadcrumb_label', 'use link_text')
        link_text(page)
      end

      def current_item?(item)
        request.path == item.abspath
      end

      def current_menu_item_class
        'current'
      end

      def current_breadcrumb_class
        nil
      end
    end
  end
end
