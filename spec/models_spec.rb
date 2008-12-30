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

  def be_assigned_to(permalink)
    HaveCategory.new(permalink)
  end
end

describe "Article" do
  include ModelFactory
  include ModelMatchers
  
  before(:each) do
    Nesta::Configuration.stub!(:configuration).and_return({
      "content" => File.join(File.dirname(__FILE__), ["fixtures"])
    })
  end
  
  after(:each) do
    remove_fixtures
  end
  
  describe "when finding articles" do
    before(:each) do
      ["Article 1", "Article 2"].each do |title|
        permalink = title.gsub(" ", "-").downcase
        create_article(:title => title, :permalink => permalink)
      end
    end
    
    it "should be possible to find all articles" do
      Article.find_all.should have(2).articles
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
      @article.should be_assigned_to("the-apple")
      @article.should be_assigned_to("banana")
    end
    
    it "should sort categories by heading" do
      @article.categories.first.heading.should == "Apple"
    end
    
    it "should not be assigned to non-existant category" do
      delete_page(:category, "banana")
      @article.should_not be_assigned_to("banana")
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
      @date, @summary = create_article_with_metadata
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
      @article.to_html.should include("<h1>My article</h1>")
    end
    
    it "should not include metadata in the HTML" do
      @article.to_html.should_not have_tag("p", /^Date/)
    end
    
    it "should retrieve date published from metadata" do
      @article.date.should == @date
    end
    
    it "should retrieve summary text from metadata" do
      @article.summary.should == @summary
    end
  end
  
  describe "without metadata" do
    before(:each) do
      create_article(:metadata => {})
      @article = Article.find_all.first
    end
    
    it "should parse heading correctly" do
      @article.to_html.should have_tag("h1", "My article")
      @article.date.should be_nil
    end
  end
end

describe "Category" do
  include ModelFactory
  
  before(:each) do
    Nesta::Configuration.stub!(:configuration).and_return({
      "content" => File.join(File.dirname(__FILE__), ["fixtures"])
    })
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
  end
  
  describe "when finding articles" do
    before(:each) do
      create_category
      create_article(:metadata => { "categories" => "my-category" })
      create_article(:permalink => "second-article")
      @article = Article.find_by_permalink("my-article")
      @category = Category.find_by_permalink("my-category")
    end

    it "should find articles assigned to category" do
      @category.articles.should have(1).item
      @category.articles.first.permalink.should == "my-article"
    end
  end
end