require "rubygems"
require "dm-core"
begin
  require "rdiscount"
rescue LoadError
  require "bluecloth"
  Markdown = BlueCloth
end

db_path = File.join(File.dirname(__FILE__), "..", "db", "#{Sinatra.env}.db")
DataMapper.setup(:default, "sqlite3://#{File.expand_path(db_path)}")

class FileModel
  def self.find_all
    file_pattern = File.join(self.path, "*.mdown")
    Dir.glob(file_pattern).map { |path| new(path) }
  end
  
  def self.find_by_permalink(permalink)
    new(File.join(self.path, "#{permalink}.mdown"))
  end

  def initialize(filename)
    @filename = filename
  end

  def permalink
    File.basename(@filename, ".*")
  end

  def date
    metadata("date")
  end
  
  def heading
    markup =~ /^#\s*(.*)/
    Regexp.last_match(1)
  end
  
  def to_html
    Markdown.new(markup).to_html
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
      text.split("\n").first =~ /^\w+\s*:/
    end
    
    def parse_file
      first_para, remaining = File.open(@filename).read.split("\n\n", 2)
      if paragraph_is_metadata(first_para)
        @markup = remaining
        @metadata = {}
        for line in first_para.split("\n") do
          key, value = line.split(/\s*:\s*/)
          @metadata[key.downcase] = value
        end
      else
        @markup = [first_para, remaining].join("\n\n")
        @metadata = {}
      end
    end
end

class Article < FileModel
  def self.path
    Nesta::Configuration.article_path
  end
    
  def categories
    categories = metadata("categories")
    permalinks = if categories.nil?
      []
    else
      categories.split(",").map { |p| p.strip }
    end
    permalinks = permalinks.select do |permalink|
      file = File.join(Nesta::Configuration.category_path, "#{permalink}.mdown")
      File.exist?(file)
    end
    permalinks.map { |permalink| Category.find_by_permalink(permalink) }
  end
end

class Category < FileModel
  def self.path
    Nesta::Configuration.category_path
  end

  def self.find_all
    super.sort { |x, y| x.heading <=> y.heading }
  end
  
  def ==(other)
    self.permalink == other.permalink
  end
  
  def articles
    Article.find_all.select do |article|
      article.categories.include? self
    end
  end
end

class Comment
  include DataMapper::Resource
  property :id, Serial
end

DataMapper.auto_upgrade!
