require 'time'

Tilt.register Tilt::MarukuTemplate, 'mdown'
Tilt.register Tilt::KramdownTemplate, 'mdown'
Tilt.register Tilt::BlueClothTemplate, 'mdown'
Tilt.register Tilt::RDiscountTemplate, 'mdown'
Tilt.register Tilt::RedcarpetTemplate, 'mdown'

module Nesta
  class HeadingNotSet < RuntimeError; end
  class LinkTextNotSet < RuntimeError; end
  class MetadataParseError < RuntimeError; end

  class FileModel
    FORMATS = [:mdown, :haml, :textile]
    @@page_cache = {}
    @@filename_cache = {}

    attr_reader :filename, :mtime

    class CaseInsensitiveHash < Hash
      def [](key)
        super(key.to_s.downcase)
      end
    end

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

    def self.find_file_for_path(path)
      if ! @@filename_cache.has_key?(path)
        FORMATS.each do |format|
          [path, File.join(path, 'index')].each do |basename|
            filename = model_path("#{basename}.#{format}")
            if File.exist?(filename)
              @@filename_cache[path] = filename
              break
            end
          end
        end
      end
      @@filename_cache[path]
    end

    def self.needs_loading?(path, filename)
      @@page_cache[path].nil? || File.mtime(filename) > @@page_cache[path].mtime
    end

    def self.load(path)
      if (filename = find_file_for_path(path)) && needs_loading?(path, filename)
        @@page_cache[path] = self.new(filename)
      end
      @@page_cache[path]
    end

    def self.purge_cache
      @@page_cache = {}
      @@filename_cache = {}
    end

    def self.menu_items
      Nesta.deprecated('Page.menu_items', 'see Menu.top_level and Menu.for_path')
      Menu.top_level
    end

    def initialize(filename)
      @filename = filename
      @format = filename.split('.').last.to_sym
      if File.zero?(filename)
        @metadata = {}
        @markup = ''
      else
        @metadata, @markup = parse_file
      end
      @mtime = File.mtime(filename)
    end

    def index_page?
      @filename =~ /\/?index\.\w+$/
    end

    def abspath
      page_path = @filename.sub(Nesta::Config.page_path, '')
      if index_page?
        File.dirname(page_path)
      else
        File.join(File.dirname(page_path), File.basename(page_path, '.*'))
      end
    end

    def path
      abspath.sub(/^\//, '')
    end

    def permalink
      File.basename(path)
    end

    def layout
      (metadata('layout') || 'layout').to_sym
    end

    def template
      (metadata('template') || 'page').to_sym
    end

    def to_html(scope = nil)
      convert_to_html(@format, scope, markup)
    end

    def last_modified
      @last_modified ||= File.stat(@filename).mtime
    end

    def description
      metadata('description')
    end

    def keywords
      metadata('keywords')
    end
    
    def metadata(key)
      @metadata[key]
    end

    def flagged_as?(flag)
      flags = metadata('flags')
      flags && flags.split(',').map { |name| name.strip }.include?(flag)
    end

    def parse_metadata(first_paragraph)
      is_metadata = first_paragraph.split("\n").first =~ /^[\w ]+:/
      raise MetadataParseError unless is_metadata
      metadata = CaseInsensitiveHash.new
      first_paragraph.split("\n").each do |line|
        key, value = line.split(/\s*:\s*/, 2)
        next if value.nil?
        metadata[key.downcase] = value.chomp
      end
      metadata
    end

    private
      def markup
        @markup
      end

      def parse_file
        contents = File.open(@filename).read
      rescue Errno::ENOENT
        raise Sinatra::NotFound
      else
        first_paragraph, remaining = contents.split(/\r?\n\r?\n/, 2)
        begin
          return parse_metadata(first_paragraph), remaining
        rescue MetadataParseError
          return {}, contents
        end
      end

      def add_p_tags_to_haml(text)
        contains_tags = (text =~ /^\s*%/)
        if contains_tags
          text
        else
          text.split(/\r?\n/).inject('') do |accumulator, line|
            accumulator << "%p #{line}\n"
          end
        end
      end

      def convert_to_html(format, scope, text)
        text = add_p_tags_to_haml(text) if @format == :haml
        template = Tilt[format].new { text }
        template.render(scope)
      end
  end

  class Page < FileModel
    def self.model_path(basename = nil)
      Nesta::Config.page_path(basename)
    end

    def self.find_by_path(path)
      page = load(path)
      page && page.hidden? ? nil : page
    end

    def self.find_all
      super.select { |p| ! p.hidden? }
    end

    def self.find_articles
      find_all.select do |page|
        page.date && page.date < DateTime.now
      end.sort { |x, y| y.date <=> x.date }
    end

    def ==(other)
      other.respond_to?(:path) && (self.path == other.path)
    end

    def draft?
      flagged_as?('draft')
    end

    def hidden?
      draft? && Nesta::App.production?
    end

    def heading
      regex = case @format
        when :mdown
          /^#\s*(.*?)(\s*#+|$)/
        when :haml
          /^\s*%h1\s+(.*)/
        when :textile
          /^\s*h1\.\s+(.*)/
        end
      markup =~ regex
      Regexp.last_match(1) or raise HeadingNotSet, "#{abspath} needs a heading"
    end

    def link_text
      metadata('link text') || heading
    rescue HeadingNotSet
      raise LinkTextNotSet, "Need to link to '#{abspath}' but can't get link text"
    end
  
    def title
      metadata('title') || link_text
    rescue LinkTextNotSet
      return Nesta::Config.title if abspath == '/'
      raise
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
      metadata('atom id')
    end

    def read_more
      metadata('read more') || Nesta::Config.read_more
    end

    def summary
      if summary_text = metadata("summary")
        summary_text.gsub!('\n', "\n")
        convert_to_html(@format, nil, summary_text)
      end
    end

    def body_markup
      case @format
        when :mdown
          markup.sub(/^#[^#].*$\r?\n(\r?\n)?/, '')
        when :haml
          markup.sub(/^\s*%h1\s+.*$\r?\n(\r?\n)?/, '')
        when :textile
          markup.sub(/^\s*h1\.\s+.*$\r?\n(\r?\n)?/, '')
      end
    end

    def body(scope = nil)
      convert_to_html(@format, scope, body_markup)
    end

    def categories
      paths = category_strings.map { |specifier| specifier.sub(/:-?\d+$/, '') }
      valid_paths(paths).map { |p| Page.find_by_path(p) }
    end

    def priority(category)
      category_string = category_strings.detect do |string|
        string =~ /^#{category}([,:\s]|$)/
      end
      category_string && category_string.split(':', 2)[-1].to_i 
    end

    def parent
      if abspath == '/'
        nil
      else
        parent_path = File.dirname(path)
        while parent_path != '.' do
          parent = Page.load(parent_path)
          return parent unless parent.nil?
          parent_path = File.dirname(parent_path)
        end
        return categories.first unless categories.empty?
        Page.load('index')
      end
    end

    def pages
      in_category = Page.find_all.select do |page|
        page.date.nil? && page.categories.include?(self)
      end
      in_category.sort do |x, y|
        by_priority = y.priority(path) <=> x.priority(path)
        if by_priority == 0
          x.link_text.downcase <=> y.link_text.downcase
        else
          by_priority
        end
      end
    end

    def articles
      Page.find_articles.select { |article| article.categories.include?(self) }
    end

    def receives_comments?
      ! date.nil?
    end

    private
      def category_strings
        strings = metadata('categories')
        strings.nil? ? [] : strings.split(',').map { |string| string.strip }
      end

      def valid_paths(paths)
        page_dir = Nesta::Config.page_path
        paths.select do |path|
          FORMATS.detect do |format|
            [path, File.join(path, 'index')].detect do |candidate|
              File.exist?(File.join(page_dir, "#{candidate}.#{format}"))
            end
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
