require File.join(File.dirname(__FILE__), "model_factory")
require File.join(File.dirname(__FILE__), "spec_helper")

describe "sitemap XML" do
  include ModelFactory
  include RequestSpecHelper
  include Sinatra::Test
  
  before(:each) do
    stub_configuration
    create_category { |f| mock_file_stat(:stub!, f, "3 Jan 2009, 15:07") }
    create_article { |f| mock_file_stat(:stub!, f, "3 Jan 2009, 15:10") }
    get "/sitemap.xml"
  end
  
  after(:each) do
    remove_fixtures
  end
  
  it "should render successfully" do
    @response.should be_ok
  end
  
  it "should have a urlset tag" do
    namespace = "http://www.sitemaps.org/schemas/sitemap/0.9"
    body.should have_tag("/urlset[@xmlns=#{namespace}]")
  end
  
  it "should reference the home page" do
    body.should have_tag("/urlset/url/loc", "http://example.org")
  end
  
  it "should request that home page is checked frequently" do
    body.should have_tag("/urlset/url") do |url|
      url.should have_tag("loc", "http://example.org")
      url.should have_tag("changefreq", "daily")
      url.should have_tag("priority", "1.0")
    end
  end
  
  it "should set the homepage lastmod from latest article" do
    body.should have_tag("/urlset/url") do |url|
      url.should have_tag("loc", "http://example.org")
      url.should have_tag("lastmod", /^2009-01-03T15:10:00/)
    end
  end
  
  it "should reference category pages" do
    body.should have_tag("/urlset/url/loc", "http://example.org/my-category")
  end
  
  it "should reference article pages" do
    body.should have_tag(
        "/urlset/url/loc", "http://example.org/articles/my-article")
  end
end

describe "sitemap XML with path prefixes" do
  include ModelFactory
  include RequestSpecHelper
  include Sinatra::Test

  before(:each) do
    stub_configuration
    stub_config_key("prefixes", { "category" => "/cat", "article" => "/foo" })
    create_category { |f| mock_file_stat(:stub!, f, "3 Jan 2009, 15:07") }
    create_article { |f| mock_file_stat(:stub!, f, "3 Jan 2009, 15:10") }
    get "/sitemap.xml"
  end
  
  after(:each) do
    remove_fixtures
  end
  
  it "should use prefix for category pages" do
    body.should have_tag(
        "/urlset/url/loc", "http://example.org/cat/my-category")
  end
  
  it "should use prefix for article pages" do
    body.should have_tag(
        "/urlset/url/loc", "http://example.org/foo/my-article")
  end
end

describe "sitemap XML lastmod" do
  include ModelFactory
  include RequestSpecHelper
  include Sinatra::Test
  
  before(:each) do
    stub_configuration
  end
  
  after(:each) do
    remove_fixtures
  end
  
  it "should be set for file based page" do
    create_article do |filename|
      mock_file_stat(:stub!, filename, "3 January 2009, 15:37:01")
    end
    get "/sitemap.xml"
    body.should have_tag("url") do |url|
      url.should have_tag("loc", /my-article$/)
      url.should have_tag("lastmod", /^2009-01-03T15:37:01/)
    end
  end
  
  it "should be set to latest page for home page" do
    create_article(:permalink => "article-1") do |filename|
      mock_file_stat(:should_receive, filename, "4 January 2009")
    end
    create_article(:permalink => "article-2") do |filename|
      mock_file_stat(:should_receive, filename, "3 January 2009")
    end
    get "/sitemap.xml"
    body.should have_tag("url") do |url|
      url.should have_tag("loc", "http://example.org")
      url.should have_tag("lastmod", /^2009-01-04/)
    end
  end
end
