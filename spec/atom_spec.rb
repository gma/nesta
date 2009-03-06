require File.join(File.dirname(__FILE__), "model_factory")
require File.join(File.dirname(__FILE__), "spec_helper")

describe "atom feed" do
  include ModelFactory
  include RequestSpecHelper
  include Sinatra::Test
  
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
    @response.should be_ok
  end
  
  it "should use Atom's XML namespace" do
    body.should have_tag("/feed[@xmlns=http://www.w3.org/2005/Atom]")
  end
  
  it "should have an ID element" do
    body.should have_tag("/feed/id", "tag:example.org,2009:/articles")
  end
  
  it "should have an alternate link element" do
    body.should have_tag("/feed/link[@rel=alternate][@href=http://example.org]")
  end

  it "should have a self link element" do
    body.should have_tag(
        "/feed/link[@rel=self][@href=http://example.org/articles.xml]")
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
      11.times do |i|
        create_article(
          :title => "Article #{i + 1}",
          :permalink => "article-#{i + 1}",
          :metadata => {
            "categories" => "my-category",
            "date" => "#{i + 1} January 2009"
          },
          :content => "Blah blah\n\n## Heading\n\n"
        )
      end
      create_category
      get "/articles.xml"
    end
    
    it "should set title" do
      body.should have_tag("entry/title", "Article 11")
    end
    
    it "should link to the HTML version" do
      url = "http://example.org/articles/article-11"
      body.should have_tag(
          "entry/link[@href=#{url}][@rel=alternate][@type=text/html]")
    end
    
    it "should define unique ID" do
      body.should have_tag(
          "entry/id", "tag:example.org,2009-01-11:/articles/article-11")
    end
    
    it "should specify date published" do
      body.should have_tag("entry/published", "2009-01-11T00:00:00+00:00")
    end

    it "should specify article categories" do
      body.should have_tag("category[@term=my-category]")
    end

    it "should have article content" do
      body.should have_tag("entry/content[@type=html]", /<h2[^>]*>Heading<\/h2>/)
    end
    
    it "should not include article heading in content" do
      body.should_not have_tag("entry/summary", /Article 11/)
    end
    
    it "should list the latest 10 articles" do
      body.should have_tag("entry", :count => 10)
      body.should_not have_tag("entry/title", "Article 1")
    end
  end
  
  describe "article with no date" do
    before(:each) do
      create_article(:permalink => "no-date")
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

describe "atom feed with article prefix" do
  include ModelFactory
  include RequestSpecHelper
  include Sinatra::Test

  before(:each) do
    stub_configuration
    stub_config_key("prefixes", { "article" => "/foo" })
  end

  after(:each) do
    remove_fixtures
  end
  
  it "should incldue article prefix in feed" do
    create_article(
      :permalink => "article-1",
      :metadata => {
        "date" => "1 January 2009"
      }
    )
    get "/articles.xml"
    body.should have_tag("link[@href=http://example.org/foo/article-1]")
  end
end
