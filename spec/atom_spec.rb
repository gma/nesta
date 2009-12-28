require File.join(File.dirname(__FILE__), "model_factory")
require File.join(File.dirname(__FILE__), "spec_helper")

describe "atom feed" do
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
    stub_config_key("author", {
      "name" => "Fred Bloggs",
      "uri" => "http://fredbloggs.com",
      "email" => "fred@fredbloggs.com"
    })
    get "/articles.xml"
  end
  
  after(:each) do
    remove_fixtures
  end
  
  it "should render successfully" do
    last_response.should be_ok
  end
  
  it "should use Atom's XML namespace" do
    body.should have_tag("/feed[@xmlns=http://www.w3.org/2005/Atom]")
  end
  
  it "should have an ID element" do
    body.should have_tag("/feed/id", "tag:example.org,2009:/")
  end
  
  it "should have an alternate link element" do
    body.should have_tag("/feed/link[@rel=alternate][@href='http://example.org']")
  end

  it "should have a self link element" do
    body.should have_tag(
        "/feed/link[@rel=self][@href='http://example.org/articles.xml']")
  end
  
  it "should have title and subtitle" do
    body.should have_tag("/feed/title[@type=text]", "My blog")
    body.should have_tag("/feed/subtitle[@type=text]", "about stuff")
  end
  
  it "should include the author details" do
    body.should have_tag("/feed/author/name", "Fred Bloggs")
    body.should have_tag("/feed/author/uri", "http://fredbloggs.com")
    body.should have_tag("/feed/author/email", "fred@fredbloggs.com")
  end

  describe "for article" do
    before(:each) do
      @heading = "Heading"
      @articles = []
      @category = create_category
      11.times do |i|
        @articles << create_article(
          :heading => "Article #{i + 1}",
          :path => "article-#{i + 1}",
          :metadata => {
            "categories" => @category.path,
            "date" => "#{i + 1} January 2009"
          },
          :content => "Blah blah\n\n## #{@heading}\n\n"
        )
      end
      @article = @articles.last
      get "/articles.xml"
    end
    
    it "should set title" do
      body.should have_tag("entry/title", "Article 11")
    end
    
    it "should link to the HTML version" do
      url = "http://example.org/#{@article.path}"
      body.should have_tag(
          "entry/link[@href='#{url}'][@rel=alternate][@type='text/html']")
    end
    
    it "should define unique ID" do
      body.should have_tag(
          "entry/id", "tag:example.org,2009-01-11:#{@article.abspath}")
    end
    
    it "should specify date published" do
      body.should have_tag("entry/published", "2009-01-11T00:00:00+00:00")
    end

    it "should specify article categories" do
      body.should have_tag("category[@term=#{@category.permalink}]")
    end

    it "should have article content" do
      body.should have_tag(
          "entry/content[@type=html]", /<h2[^>]*>#{@heading}<\/h2>/)
    end
    
    it "should not include article heading in content" do
      body.should_not have_tag("entry/summary", /#{@article.heading}/)
    end
    
    it "should list the latest 10 articles" do
      body.should have_tag("entry", :count => 10)
      body.should_not have_tag("entry/title", @articles.first.heading)
    end
  end
  
  describe "page with no date" do
    before(:each) do
      create_category(:path => "no-date")
      get "/articles.xml"
    end

    it "should not appear in feed" do
      body.should_not have_tag("entry/id", /tag.*no-date/)
    end
  end
  
  describe "article with atom ID" do
    it "should use pre-defined ID" do
      create_article(:metadata => {
        "date" => "1 January 2009",
        "atom id" => "use-this-id"
      })
      get "/articles.xml"
      body.should have_tag("entry/id", "use-this-id")
    end
  end
end
