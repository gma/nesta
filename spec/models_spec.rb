require File.join(File.dirname(__FILE__), "spec_helper")

describe "Article" do
  include ArticleFactory
  
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
  
  describe "when Markdown" do
    before(:each) do
      create_article
      @article = Article.find_all.first
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
    
    it "should retrieve load date published from metadata" do
      @article.date.should == "29 December 2008"
    end
    
    it "should not include metadata in the HTML" do
      @article.to_html.should_not have_tag("p", /^Date/)
    end
  end
  
  describe "when Markdown article has no metadata" do
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
