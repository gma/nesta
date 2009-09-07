require File.join(File.dirname(__FILE__), "model_factory")
require File.join(File.dirname(__FILE__), "spec_helper")

module ModelMatchers
  class HaveCategory
    def initialize(permalink)
      @category = permalink
    end

    def matches?(article)
      @article = article
      article.categories.map { |c| c.permalink }.include?(@category)
    end

    def failure_message
      "expected '#{@article.permalink}' to be assigned to #{@category}"
    end

    def negative_failure_message
      "'#{@article.permalink}' should not be assigned to #{@category}"
    end
  end

  def be_in_category(permalink)
    HaveCategory.new(permalink)
  end
  
  class HaveComment
    def initialize(basename)
      @comment = Comment.find_by_basename(basename)
    end
    
    def matches?(article)
      @article = article
      article.comments.map { |c| c.basename }.include?(@comment.basename)
    end
    
    def failure_message
      "expected '#{@article.permalink}' to have comment '#{@comment.basename}'"
    end
    
    def negative_failure_message
      "'#{@article.permalink}' should not have comment '#{@comment.basename}'"
    end
  end
  
  def have_comment(basename)
    HaveComment.new(basename)
  end
end

describe "Article" do
  include ModelFactory
  include ModelMatchers

  before(:each) do
    stub_configuration
  end
  
  after(:each) do
    remove_fixtures
  end
  
  describe "when finding articles" do
    before(:each) do
      create_article(:title => "Article 1", :permalink => "article-1")
      create_article(:title => "Article 2",
                     :permalink => "article-2",
                     :metadata => { "date" => "31 December 2008" })
      create_article(:title => "Article 3",
                     :permalink => "foo/article-3",
                     :metadata => { "date" => "30 December 2008" })
    end
    
    it "should be possible to find all pages with dates" do
      Article.find_all.should have(2).articles
    end
    
    it "should return articles in reverse chronological order" do
      article1, article2 = Article.find_all[0..1]
      article1.date.should > article2.date
    end
    
    it "should be possible to find an article by permalink" do
      Article.find_by_permalink("article-2").heading.should == "Article 2"
    end
  end
  
  describe "when assigned to categories" do
    before(:each) do
      create_category(:title => "Apple", :permalink => "the-apple")
      create_category(:title => "Banana", :permalink => "banana")
      create_article(:metadata => { "categories" => "banana, the-apple" })
      @article = Article.find_by_permalink("my-article")
    end
    
    it "should be possible to list the categories" do
      @article.categories.should have(2).items
      @article.should be_in_category("the-apple")
      @article.should be_in_category("banana")
    end
    
    it "should sort categories by heading" do
      @article.categories.first.heading.should == "Apple"
    end
    
    it "should not be assigned to non-existant category" do
      delete_page(:category, "banana")
      @article.should_not be_in_category("banana")
    end
  end
  
  describe "when has parent category" do
    before(:each) do
      create_category
      create_article(:metadata => { "parent" => "my-category" })
      @article = Article.find_by_permalink("my-article")
    end
    
    it "should be possible to retrieve the parent" do
      @article.parent.should == Category.find_by_permalink("my-category")
    end
  end
  
  describe "when not assigned to categories" do
    it "should be possible to list categories" do
      create_article
      Article.find_by_permalink("my-article").categories.should be_empty
    end
  end
  
  describe "with metadata" do
    before(:each) do
      @date = "07 September 2009"
      @keywords = "things, stuff"
      @description = "Page about stuff"
      @summary = 'Multiline\n\nsummary'
      @read_more = "Continue at your leisure"
      create_article(:metadata => {
        "date" => @date.gsub("September", "Sep"),
        "description" => @description,
        "keywords" => @keywords,
        "summary" => @summary,
        "read more" => @read_more
      })
      @article = Article.find_by_permalink("my-article")
    end
    
    it "should set permalink from filename" do
      @article.permalink.should == "my-article"
    end
    
    it "should retrieve heading" do
      @article.heading.should == "My article"
    end
    
    it "should set heading from first h1 tag" do
      create_article(:permalink => "headings", :content => '# Second heading')
      Article.find_by_permalink("headings").heading.should == "My article"
    end

    it "should be possible to convert an article to HTML" do
      @article.to_html.should have_tag("h1", "My article")
    end
    
    it "should not include metadata in the HTML" do
      @article.to_html.should_not have_tag("p", /^Date/)
    end
    
    it "should not include heading in body" do
      @article.body.should_not have_tag("h1", "My article")
    end

    it "should retrieve description from metadata" do
      @article.description.should == @description
    end
    
    it "should retrieve keywords from metadata" do
      @article.keywords.should == @keywords
    end
    
    it "should retrieve date published from metadata" do
      @article.date.strftime("%d %B %Y").should == @date
    end
    
    it "should retrieve read more link from metadata" do
      @article.read_more.should == @read_more
    end
    
    it "should retrieve summary text from metadata" do
      @article.summary.should match(/#{@summary.split('\n\n').first}/)
    end
    
    it "should treat double newline chars as paragraph break in summary" do
      @article.summary.should match(/#{@summary.split('\n\n').last}/)
    end
  end
  
  describe "without metadata" do
    before(:each) do
      create_article
      @article = Article.find_all.first
    end
    
    it "should parse heading correctly" do
      @article.to_html.should have_tag("h1", "My article")
    end
    
    it "should have default read more link text" do
      @article.read_more.should == "Continue reading"
    end
    
    it "should not have description" do
      @article.description.should be_nil
    end
    
    it "should not have keywords" do
      @article.keywords.should be_nil
    end
  end
  
  describe "when checking last modification time" do
    before(:each) do
      create_article
      @article = Article.find_all.first
    end
    
    it "should check filesystem" do
      mock_file_stat(:should_receive, @article.filename, "3 January 2009")
      @article.last_modified.should == Time.parse("3 January 2009")
    end
  end
  
  describe "when has comments" do
    before(:each) do
      create_article
      [12, 13].each do |day|
        create_comment(:metadata => {
          "author" => "Fred Bloggs",
          "date" => "#{day} Jan 2009",
          "article" => "my-article"
        })
      end
      @article = Article.find_by_permalink("my-article")
    end
    
    it "should list comments in chronological order" do
      @article.comments.should have(2).items
      @article.comments[0].date.should < @article.comments[1].date
    end
    
    it "should only find comments made on this article" do
      comment = create_comment(:metadata => {
        "author" => "Fred Dibnah",
        "date" => "12 Jan 2009",
        "article" => "other-article"
      })
      @article.should_not have_comment("20090112-000000-fred-dibnah")
    end
  end
end

describe "Comment" do
  include ModelFactory
  
  before(:each) do
    stub_configuration
    create_comment
    @comment = Comment.find_all.first
  end
  
  after(:each) do
    remove_fixtures
  end
  
  it "should have author name" do
    @comment.author.should == "Fred Bloggs"
  end
  
  it "should have author URL" do
    @comment.author_url.should == "http://bloggs.com/~fred"
  end
  
  it "should have author email" do
    @comment.author_email.should == "fred@bloggs.com"
  end
  
  it "should have a creation date" do
    @comment.date.should_not be_nil
  end
  
  it "should have body text" do
    @comment.body.should == "Great article.\n"
  end
end

describe "Category" do
  include ModelFactory
  
  before(:each) do
    stub_configuration
  end
  
  after(:each) do
    remove_fixtures
  end
  
  describe "when finding categories" do
    before(:each) do
      create_category(:title => "Apple", :permalink => "the-apple")
      create_category(:title => "Banana", :permalink => "banana")
    end
    
    it "should be possible to find all categories" do
      all_categories = Category.find_all
      all_categories.should have(2).categories
      all_categories.first.heading.should == "Apple"
    end
  
    it "should be possible to find a category by permalink" do
      Category.find_by_permalink("banana").heading.should == "Banana"
    end
    
    it "should not be possible to find non existant category" do
      Category.find_by_permalink("no-such-category").should be_nil
    end
  end
  
  describe "when finding articles" do
    before(:each) do
      create_category
      create_article(:titile => "Article 1", :permalink => "article-1")
      create_article(:title => "Article 2",
                     :permalink => "article-2",
                     :metadata => {
                       "date" => "30 December 2008",
                       "categories" => "my-category"
                      })
      create_article(:title => "Article 3",
                     :permalink => "article-3",
                     :metadata => {
                       "date" => "31 December 2008",
                       "categories" => "my-category"
                      })
      @article = Article.find_by_permalink("my-article")
      @category = Category.find_by_permalink("my-category")
    end

    it "should find articles assigned to category" do
      @category.articles.should have(2).items
    end
    
    it "should return articles in reverse chronological order" do
      @category.articles.first.permalink.should == "article-3"
    end
  end
end
