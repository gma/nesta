require "time"

require "rubygems"
require "maruku"
require "redcloth"

module Nesta
  class FileModel
    FORMATS = [:mdown, :haml, :textile]
    @@cache = {}

    attr_reader :filename, :mtime

    def self.model_path(basename = nil)
      Nesta::Config.content_path(basename)
    end

    def self.find_all
      file_pattern = File.join(model_path, "**", "*.{#{FORMATS.join(',')}}")
      Dir.glob(file_pattern).map do |path|
        relative = path.sub("#{model_path}/", "")
        load(relative.sub(/\.(#{FORMATS.join('|')})/, ""))
      end
    end

    def self.needs_loading?(path, filename)
      @@cache[path].nil? || File.mtime(filename) > @@cache[path].mtime
    end

    def self.load(path)
      FORMATS.each do |format|
        filename = model_path("#{path}.#{format}")
        if File.exist?(filename) && needs_loading?(path, filename)
          @@cache[path] = self.new(filename)
          break
        end
      end
      @@cache[path]
    end

    def self.purge_cache
      @@cache = {}
    end

    def self.menu_items
      Nesta.deprecated('Page.menu_items', 'see Menu.top_level and Menu.for_path')
      Menu.top_level
    end

    def initialize(filename)
      @filename = filename
      @format = filename.split(".").last.to_sym
      parse_file
      @mtime = File.mtime(filename)
    end

    def permalink
      File.basename(@filename, ".*")
    end

    def path
      abspath.sub(/^\//, "")
    end

    def abspath
      prefix = File.dirname(@filename).sub(Nesta::Config.page_path, "")
      File.join(prefix, permalink)
    end

    def layout
      (metadata("layout") || "layout").to_sym
    end

    def template
      (metadata("template") || "page").to_sym
    end

    def to_html(scope = nil)
      case @format
      when :mdown
        Maruku.new(markup).to_html
      when :haml
        Haml::Engine.new(markup).to_html(scope || Object.new)
      when :textile
        RedCloth.new(markup).to_html
      end
    end

    def last_modified
      @last_modified ||= File.stat(@filename).mtime
    end

    def description
      metadata("description")
    end

    def keywords
      metadata("keywords")
    end
    
    def metadata(key)
      @metadata[key]
    end

    private
    def markup
      @markup
    end

    def paragraph_is_metadata(text)
      text.split("\n").first =~ /^[\w ]+:/
    end

    def parse_file
      first_para, remaining = File.open(@filename).read.split(/\r?\n\r?\n/, 2)
      @metadata = {}
      if paragraph_is_metadata(first_para)
        @markup = remaining
        for line in first_para.split("\n") do
          key, value = line.split(/\s*:\s*/, 2)
          @metadata[key.downcase] = value.chomp
        end
      else
        @markup = [first_para, remaining].join("\n\n")
      end
    rescue Errno::ENOENT  # file not found
      raise Sinatra::NotFound
    end
  end

  class Page < FileModel
    def self.model_path(basename = nil)
      Nesta::Config.page_path(basename)
    end

    def self.find_by_path(path)
      load(path)
    end

    def self.find_articles
      find_all.select do |page|
        page.date && page.date < DateTime.now
      end.sort { |x, y| y.date <=> x.date }
    end

    def ==(other)
      other.respond_to?(:path) && (self.path == other.path)
    end

    def heading
      regex = case @format
              when :mdown
                /^#\s*(.*)/
              when :haml
                /^\s*%h1\s+(.*)/
              when :textile
                /^\s*h1\.\s+(.*)/
              end
      markup =~ regex
      Regexp.last_match(1)
    end

    def date(format = nil)
      @date ||= if metadata("date")
                  if format == :xmlschema
                    Time.parse(metadata("date")).xmlschema
                  else
                    DateTime.parse(metadata("date"))
                  end
                end
    end

    def atom_id
      metadata("atom id")
    end

    def read_more
      metadata("read more") || "Continue reading"
    end

    def summary
      if summary_text = metadata("summary")
        summary_text.gsub!('\n', "\n")
        case @format
        when :textile
          RedCloth.new(summary_text).to_html
        else
          Maruku.new(summary_text).to_html
        end
      end
    end

    def body
      case @format
      when :mdown
        body_text = markup.sub(/^#[^#].*$\r?\n(\r?\n)?/, "")
        Maruku.new(body_text).to_html
      when :haml
        body_text = markup.sub(/^\s*%h1\s+.*$\r?\n(\r?\n)?/, "")
        Haml::Engine.new(body_text).render
      when :textile
        body_text = markup.sub(/^\s*h1\.\s+.*$\r?\n(\r?\n)?/, "")
        RedCloth.new(body_text).to_html
      end
    end

    def categories
      categories = metadata("categories")
      paths = categories.nil? ? [] : categories.split(",").map { |p| p.strip }
      valid_paths(paths).map { |p| Page.find_by_path(p) }.sort do |x, y|
        x.heading.downcase <=> y.heading.downcase
      end
    end

    def parent
      Page.load(File.dirname(path))
    end

    def pages
      Page.find_all.select do |page|
        page.date.nil? && page.categories.include?(self)
      end.sort do |x, y|
        x.heading.downcase <=> y.heading.downcase
      end
    end

    def articles
      Page.find_articles.select { |article| article.categories.include?(self) }
    end

    private
      def valid_paths(paths)
        paths.select do |path|
          FORMATS.detect do |format|
            File.exist?(File.join(Nesta::Config.page_path, "#{path}.#{format}"))
          end
        end
      end
  end

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

    private
      def self.append_menu_item(menu, file, depth)
        path = file.readline
      rescue EOFError
      else
        page = Page.load(path.strip)
        if page
          current_depth = path.scan(INDENT).size
          if current_depth > depth
            sub_menu_for_depth(menu, depth) << [page]
          else
            sub_menu_for_depth(menu, current_depth) << page
          end
          append_menu_item(menu, file, current_depth)
        end
      end

      def self.sub_menu_for_depth(menu, depth)
        sub_menu = menu
        depth.times { sub_menu = sub_menu[-1] }
        sub_menu
      end

      def self.find_menu_item_by_path(menu, path)
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
