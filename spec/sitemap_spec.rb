require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('model_factory', File.dirname(__FILE__))

describe "sitemap XML" do
  include RequestSpecHelper
  include ModelFactory

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
    Nesta::FileModel.purge_cache
    remove_temp_directory
  end

  it "should render successfully" do
    last_response.should be_ok
  end

  it "should have a urlset tag" do
    namespace = "http://www.sitemaps.org/schemas/sitemap/0.9"
    body.should have_xpath("//urlset[@xmlns='#{namespace}']")
  end

  it "should reference the home page" do
    body.should have_xpath("//urlset/url/loc", :content => "http://example.org/")
  end

  it "should configure home page to be checked frequently" do
    body.should have_xpath("//urlset/url") do |url|
      url.should have_xpath("loc", :content => "http://example.org/")
      url.should have_xpath("changefreq", :content => "daily")
      url.should have_xpath("priority", :content => "1.0")
    end
  end

  it "should set the homepage lastmod from latest article" do
    body.should have_xpath("//urlset/url") do |url|
      url.should have_xpath("loc", :content => "http://example.org/")
      url.should have_selector("lastmod:contains('2009-01-03T15:10:00')")
    end
  end

  it "should reference category pages" do
    body.should have_xpath(
        "//urlset/url/loc", :content => "http://example.org/#{@category.path}")
  end

  it "should reference article pages" do
    body.should have_xpath(
        "//urlset/url/loc", :content => "http://example.org/#{@article.path}")
  end
end

describe "sitemap XML lastmod" do
  include ModelFactory
  include RequestSpecHelper

  before(:each) do
    stub_configuration
  end

  after(:each) do
    remove_temp_directory
    Nesta::FileModel.purge_cache
  end

  it "should be set for file based page" do
    create_article do |path|
      mock_file_stat(:stub!, path, "3 January 2009, 15:37:01")
    end
    get "/sitemap.xml"
    body.should have_selector("url") do |url|
      url.should have_selector("loc:contains('my-article')")
      url.should have_selector("lastmod:contains('2009-01-03T15:37:01')")
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
    body.should have_selector("url") do |url|
      url.should have_selector("loc:contains('http://example.org/')")
      url.should have_selector("lastmod:contains('2009-01-04')")
    end
  end
end
