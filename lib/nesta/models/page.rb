module Nesta
  class HeadingNotSet < RuntimeError; end
  class LinkTextNotSet < RuntimeError; end

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

    def draft?
      flagged_as?('draft')
    end

    def hidden?
      draft? && Nesta::App.production?
    end

    def heading
      regex = case @format
        when :mdown, :md
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
      @date ||= if metadata('date')
        if format == :xmlschema
          Time.parse(metadata('date')).xmlschema
        else
          DateTime.parse(metadata('date'))
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
      if summary_text = metadata('summary')
        summary_text.gsub!('\n', "\n")
        convert_to_html(@format, Object.new, summary_text)
      end
    end

    def body_markup
      case @format
        when :mdown, :md
          markup.sub(/^#[^#].*$\r?\n(\r?\n)?/, '')
        when :haml
          markup.sub(/^\s*%h1\s+.*$\r?\n(\r?\n)?/, '')
        when :textile
          markup.sub(/^\s*h1\.\s+.*$\r?\n(\r?\n)?/, '')
      end
    end

    def body(scope = Object.new)
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

end
