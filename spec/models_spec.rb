require File.join(File.dirname(__FILE__), "spec_helper")

describe "Article" do
  include ArticleFactory
  
  before(:each) do
    Nesta::Configuration.stub!(:configuration).and_return({
      "content" => File.join(File.dirname(__FILE__), ["fixtures"])
    })
    create_article
    @article = Article.find_all.first
  end
  
  after(:each) do
    remove_fixtures
  end
  
  it "should be possible to find all articles" do
    Article.find_all.should have(1).article
  end
  
  it "should be possible to find an article by permalink" do
    Article.find_by_permalink("my-article").heading.should == "My article"
  end
  
  describe "when reading Markdown" do
    it "should set permalink from filename" do
      @article.permalink.should == "my-article"
    end
    
    it "should retrieve heading" do
      @article.heading.should == "My article"
    end

    it "should be possible to convert an article to HTML" do
      @article.to_html.should include("<h1>My article</h1>")
    end
  end
end
