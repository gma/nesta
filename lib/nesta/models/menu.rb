module Nesta
  class Menu
    INDENT = " " * 2

    def self.full_menu
      menu = []
      menu_file = Nesta::Config.content_path('menu.txt')
      if File.exist?(menu_file)
        File.open(menu_file) { |file| append_menu_item(menu, file, 0) }
      end
      menu
    end

    def self.top_level
      full_menu.reject { |item| item.is_a?(Array) }
    end

    def self.for_path(path)
      path.sub!(Regexp.new('^/'), '')
      if path.empty?
        full_menu
      else
        find_menu_item_by_path(full_menu, path)
      end
    end

    private_class_method def self.append_menu_item(menu, file, depth)
      path = file.readline
    rescue EOFError
    else
      page = Page.load(path.strip)
      current_depth = path.scan(INDENT).size
      if page
        if current_depth > depth
          sub_menu_for_depth(menu, depth) << [page]
        else
          sub_menu_for_depth(menu, current_depth) << page
        end
      end
      append_menu_item(menu, file, current_depth)
    end

    private_class_method def self.sub_menu_for_depth(menu, depth)
      sub_menu = menu
      depth.times { sub_menu = sub_menu[-1] }
      sub_menu
    end

    private_class_method def self.find_menu_item_by_path(menu, path)
      item = menu.detect do |item|
        item.respond_to?(:path) && (item.path == path)
      end
      if item
        subsequent = menu[menu.index(item) + 1]
        item = [item]
        item << subsequent if subsequent.respond_to?(:each)
      else
        sub_menus = menu.select { |menu_item| menu_item.respond_to?(:each) }
        sub_menus.each do |sub_menu|
          item = find_menu_item_by_path(sub_menu, path)
          break if item
        end
      end
      item
    end
  end
end
