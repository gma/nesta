require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('model_factory', File.dirname(__FILE__))

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
    remove_temp_directory
  end

  it "should render successfully" do
    last_response.should be_ok
  end

  it "should use Atom's XML namespace" do
    body.should have_xpath("//feed[@xmlns='http://www.w3.org/2005/Atom']")
  end

  it "should have an ID element" do
    body.should have_selector("id:contains('tag:example.org,2009:/')")
  end

  it "should have an alternate link element" do
    body.should have_xpath("//feed/link[@rel='alternate'][@href='http://example.org/']")
  end

  it "should have a self link element" do
    body.should have_xpath(
        "//feed/link[@rel='self'][@href='http://example.org/articles.xml']")
  end

  it "should have title and subtitle" do
    body.should have_xpath("//feed/title[@type='text']", :content => "My blog")
    body.should have_xpath("//feed/subtitle[@type='text']", :content => "about stuff")
  end

  it "should include the author details" do
    body.should have_xpath("//feed/author/name", :content => "Fred Bloggs")
    body.should have_xpath("//feed/author/uri", :content => "http://fredbloggs.com")
    body.should have_xpath("//feed/author/email", :content => "fred@fredbloggs.com")
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
          :content => "Blah blah\n\n## #{@heading}\n\n[link](/foo)"
        )
      end
      @article = @articles.last
      get "/articles.xml"
    end

    it "should set title" do
      body.should have_xpath("//entry/title", :content => "Article 11")
    end

    it "should link to the HTML version" do
      url = "http://example.org/#{@article.path}"
      body.should have_xpath(
          "//entry/link[@href='#{url}'][@rel='alternate'][@type='text/html']")
    end

    it "should define unique ID" do
      body.should have_xpath(
          "//entry/id", :content => "tag:example.org,2009-01-11:#{@article.abspath}")
    end

    it "should specify date published" do
      body.should have_xpath("//entry/published", :content => "2009-01-11T00:00:00+00:00")
    end

    it "should specify article categories" do
      body.should have_xpath("//category[@term='#{@category.permalink}']")
    end

    it "should have article content" do
      body.should have_xpath "//entry/content[@type='html']" do |a|
       a.should contain "<h2>#{@heading}</h2>"
      end
    end

    it "should include hostname in URLs" do
      body.should have_xpath("//entry/content") do |c|
        c.should contain 'http://example.org/foo'
      end
    end

    it "should not include article heading in content" do
      body.should_not have_selector("summary:contains('#{@article.heading}')")
    end

    it "should list the latest 10 articles" do
      body.should have_selector("entry", :count => 10)
    end
  end

  describe "page with no date" do
    before(:each) do
      create_category(:path => "no-date")
      get "/articles.xml"
    end

    it "should not appear in feed" do
      body.should_not have_selector("entry id:contains('no-date')")
    end
  end

  describe "article with atom ID" do
    it "should use pre-defined ID" do
      create_article(:metadata => {
        "date" => "1 January 2009",
        "atom id" => "use-this-id"
      })
      get "/articles.xml"
      body.should have_xpath("//entry/id", :content => "use-this-id")
    end
  end
end
