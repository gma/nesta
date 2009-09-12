require File.join(File.dirname(__FILE__), "model_factory")
require File.join(File.dirname(__FILE__), "spec_helper")

describe "sitemap XML" do
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
    @category = create_category do |path|
      mock_file_stat(:stub!, path, "3 Jan 2009, 15:07")
    end
    @article = create_article do |path|
      mock_file_stat(:stub!, path, "3 Jan 2009, 15:10")
    end
    get "/sitemap.xml"
  end
  
  after(:each) do
    FileModel.purge_cache
    remove_fixtures
  end
  
  it "should render successfully" do
    last_response.should be_ok
  end
  
  it "should have a urlset tag" do
    namespace = "http://www.sitemaps.org/schemas/sitemap/0.9"
    body.should have_tag("/urlset[@xmlns=#{namespace}]")
  end
  
  it "should reference the home page" do
    body.should have_tag("/urlset/url/loc", "http://example.org")
  end
  
  it "should configure home page to be checked frequently" do
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
    body.should have_tag(
        "/urlset/url/loc", "http://example.org/#{@category.path}")
  end
  
  it "should reference article pages" do
    body.should have_tag(
        "/urlset/url/loc", "http://example.org/#{@article.path}")
  end
end

describe "sitemap XML lastmod" do
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
  end
  
  after(:each) do
    remove_fixtures
    FileModel.purge_cache
  end
  
  it "should be set for file based page" do
    create_article do |path|
      mock_file_stat(:stub!, path, "3 January 2009, 15:37:01")
    end
    get "/sitemap.xml"
    body.should have_tag("url") do |url|
      url.should have_tag("loc", /my-article$/)
      url.should have_tag("lastmod", /^2009-01-03T15:37:01/)
    end
  end
  
  it "should be set to latest page for home page" do
    create_article(:path => "article-1") do |path|
      mock_file_stat(:stub!, path, "4 January 2009")
    end
    create_article(:path => "article-2") do |path|
      mock_file_stat(:stub!, path, "3 January 2009")
    end
    get "/sitemap.xml"
    body.should have_tag("url") do |url|
      url.should have_tag("loc", "http://example.org")
      url.should have_tag("lastmod", /^2009-01-04/)
    end
  end
end
