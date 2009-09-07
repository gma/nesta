require "time"

require "rubygems"
require "maruku"

class FileModel
  attr_reader :filename
  
  def self.find_all
    file_pattern = File.join(self.path, "**", "*.mdown")
    Dir.glob(file_pattern).map { |path| new(path) }
  end
  
  def initialize(filename)
    @filename = filename
  end

  def permalink
    File.basename(@filename, ".*")
  end

  def path
    abspath.sub(/^\//, "")
  end
  
  def abspath
    prefix = File.dirname(@filename).sub(Nesta::Configuration.page_path, "")
    File.join(prefix, permalink)
  end
  
  def to_html
    Maruku.new(markup).to_html
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

  private
    def markup
      parse_file if @markup.nil?
      @markup
    end
    
    def metadata(key)
      parse_file if @metadata.nil?
      @metadata[key]
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
          @metadata[key.downcase] = value
        end
      else
        @markup = [first_para, remaining].join("\n\n")
      end
    rescue Errno::ENOENT  # file not found
      raise Sinatra::NotFound
    end
end

module PageModel
  module ClassMethods
    def path
      Nesta::Configuration.page_path
    end
    
    def find_by_path(path)
      file = File.join(self.path, "#{path}.mdown")
      File.exist?(file) ? new(file) : nil
    end

    def find_articles
      find_all.select { |page| page.date }.sort { |x, y| y.date <=> x.date }
    end
  end
end

class Page < FileModel
  extend PageModel::ClassMethods
  
  def ==(other)
    self.path == other.path
  end
  
  def heading
    markup =~ /^#\s*(.*)/
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
    metadata("summary") && metadata("summary").gsub('\n', "\n")
  end
  
  def body
    Maruku.new(markup.sub(/^#\s.*$\r?\n(\r?\n)?/, "")).to_html
  end
  
  def categories
    categories = metadata("categories")
    paths = if categories.nil?
      []
    else
      categories.split(",").map { |p| p.strip }
    end
    paths = paths.select do |path|
      filename = File.join(Nesta::Configuration.page_path, "#{path}.mdown")
      File.exist?(filename)
    end
    paths.map { |p| Page.find_by_path(p) }.sort { |x, y| x.heading <=> y.heading }
  end
  
  def parent
    Page.find_by_path(metadata("parent"))
  end
  
  def articles
    Page.find_articles.select { |article| article.categories.include?(self) }
  end
  
  def comments
    Comment.find_by_article(self).sort do |x, y|
      x.date <=> y.date
    end
  end
end

class Comment < FileModel
  def self.basename(time, author)
    "#{time.strftime('%Y%m%d-%H%M%S')}-#{author.gsub(" ", "-").downcase}"
  end
  
  def self.find_by_basename(basename)
    find_all.find { |c| c.basename == basename }
  end
  
  def self.find_by_article(article)
    find_all.select { |c| c.article == article.path }
  end
  
  def self.path
    Nesta::Configuration.comment_path
  end
  
  def ==(other)
    self.basename == other.basename
  end
  
  def basename
    Comment.basename(date, author)
  end
  
  def author
    metadata("author")
  end
  
  def author_url
    metadata("author url")
  end
  
  def author_email
    metadata("author email")
  end
  
  def article
    metadata("article")
  end
  
  def date
    DateTime.parse(metadata("date"))
  end
  
  def body
    markup
  end
end
