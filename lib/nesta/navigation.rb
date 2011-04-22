module Nesta
  module Navigation
    module Renderers
      def display_menu(menu, options = {})
        defaults = { :class => nil, :levels => 2}
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
            end unless not item.detect {|i| i.locales.include? current_locale}  
          end
        else
          haml_tag :li do
            haml_tag :a, :<, :href => item.abspath do
              haml_concat item.heading
            end
          end unless not item.locales.include? current_locale
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
              haml_tag :a, :href => page.abspath do
                haml_concat breadcrumb_label(page)
              end
            end
          end
          haml_tag(:li) { haml_concat breadcrumb_label(@page) }
        end
      end

      def breadcrumb_label(page)
        page.root? ? 'Home' : page.heading
      end


      def display_locales(page, options = {})
        options[:separator] ||= " , "
        options[:final] ||= " and "
        options[:use_code] ||= false
        options[:keep_own] ||= false

        locales = options[:all] ? Nesta::App.available_locales : page.locales
        locales.delete(current_locale) unless options[:keep_own]
        
        locales.each_with_index do |l, i|
          if l == current_locale and options[:keep_own] == :but_dont_link
            haml_concat (options[:use_code] ? l : R18n::Locale.load(l).title)
          else
            haml_tag :a, :<, :href => page.abspath(:locale => l) do
              haml_concat (options[:use_code] ? l : R18n::Locale.load(l).title)
            end
          end
          case i 
          when 0..(locales.count - 3) then haml_concat options[:separator]
          when (locales.count - 2) then haml_concat options[:final]
          end
        end
      end
    end
  end
end
