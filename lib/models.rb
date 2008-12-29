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

class Article
  def self.find_all
    file_pattern = File.join(Nesta::Configuration.content_path, "*.mdown")
    Dir.glob(file_pattern).map { |path| Article.new(path) }
  end
  
  def self.find_by_permalink(permalink)
    filename = File.join(Nesta::Configuration.content_path, "#{permalink}.mdown")
    Article.new(filename)
  end
  
  def initialize(filename)
    @filename = filename
  end

  def permalink
    File.basename(@filename, ".*")
  end
  
  def heading
    file_contents =~ /^#\s*(.*)/
    Regexp.last_match(1)
  end
  
  def to_html
    Markdown.new(file_contents).to_html
  end
  
  private
    def file_contents
      @file_contents ||= File.open(@filename).read
    end
end

class Comment
  include DataMapper::Resource
  property :id, Serial
end

DataMapper.auto_upgrade!
