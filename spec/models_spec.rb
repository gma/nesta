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

  describe "when reading Markdown" do
    it "should set permalink from filename" do
      @article.permalink.should == "my-article"
    end
    
    it "should retrieve heading" do
      @article.heading.should == "My article"
    end
  end
end
