require File.join(File.dirname(__FILE__), "model_factory")
require File.join(File.dirname(__FILE__), "spec_helper")

describe "layout" do
  include ModelFactory
  include RequestSpecHelper
  
  it "should not include GA JavaScript by default" do
    stub_configuration
    get "/"
    body.should_not have_tag("script", /_getTracker\("UA-1234"\)/)
  end
  
  it "should include GA JavaScript if configured" do
    stub_env_config_key("google_analytics_code", "UA-1234")
    stub_configuration
    get "/"
    body.should have_tag("script", /_getTracker\("UA-1234"\)/)
  end
end

describe "page with menus", :shared => true do
  before(:each) do
    @category = create_category
  end
  
  it "should link to menu items" do
    create_menu(@category.path)
    get @category.abspath
    body.should have_tag(
        "#sidebar ul.menu a[@href=#{@category.abspath}]", @category.heading)
  end
  
  it "should not be display menu if not configured" do
    get @category.abspath
    body.should_not have_tag("#sidebar ul.menu")
  end
end

describe "home page" do
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
    create_category
    get "/"
  end
  
  after(:each) do
    remove_fixtures
    FileModel.purge_cache
  end
  
  it_should_behave_like "page with menus"
  
  it "should render successfully" do
    last_response.should be_ok
  end
  
  it "should display title and subtitle in title tag" do
    body.should have_tag("title", "My blog - about stuff")
  end
  
  it "should display site title in h1 tag" do
    body.should have_tag("h1", /My blog/)
  end
  
  it "should display site subtitle in h1 tag" do
    body.should have_tag("h1 small", /about stuff/)
  end
  
  it "should set description meta tag" do
    body.should have_tag("meta[@name=description][@content='great web site']")
  end
  
  it "should set keywords meta tag" do
    body.should have_tag("meta[@name=keywords][@content='home, page']")
  end
  
  describe "when articles have no summary" do
    before(:each) do
      create_article
      get "/"
    end
    
    it "should display full content of article" do
      body.should have_tag("p", "Content goes here")
    end
    
    it "should not display read more link" do
      body.should_not have_tag("a", /continue/i)
    end
  end

  describe "when articles have metadata" do
    before(:each) do
      @summary = 'Multiline\n\nsummary'
      @read_more = "Continue at your leisure"
      @article = create_article(:metadata => {
        "summary" => @summary,
        "read more" => @read_more
      })
      get "/"
    end
    
    it "should display link to article in h2 tag" do
      body.should have_tag(
          "h2 a[@href=#{@article.abspath}]", /^\s*#{@article.heading}$/)
    end
    
    it "should display article summary if available" do
      body.should have_tag("p", @summary.split('\n\n').first)
    end
    
    it "should display read more link" do
      body.should have_tag("a[@href=#{@article.abspath}]", @read_more)
    end
  end
end

describe "page with meta tags", :shared => true do
  it "should set description meta tag" do
    body.should have_tag("meta[@name=description][@content='#{@description}']")
  end
  
  it "should set the keywords meta tag" do
    body.should have_tag("meta[@name=keywords][@content='#{@keywords}']")
  end
end

describe "article" do
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
    @date = "07 September 2009"
    @keywords = "things, stuff"
    @description = "Page about stuff"
    @summary = 'Multiline\n\nsummary'
    @article = create_article(:metadata => {
      "date" => @date.gsub("September", "Sep"),
      "description" => @description,
      "keywords" => @keywords,
      "summary" => @summary,
    })
  end
  
  after(:each) do
    remove_fixtures
    FileModel.purge_cache
  end
  
  describe "that's not assigned to a category" do
    before(:each) do
      get @article.abspath
    end

    it_should_behave_like "page with menus"  
    it_should_behave_like "page with meta tags"

    it "should render successfully" do
      last_response.should be_ok
    end

    it "should display the heading" do
      body.should have_tag("h1", "My article")
    end

    it "should not display category links" do
      body.should_not have_tag("div.breadcrumb div.categories", /filed in/)
    end

    it "should display the date" do
      body.should have_tag("div.date", @date)
    end

    it "should display the content" do
      body.should have_tag("p", "Content goes here")
    end
  end
  
  describe "that's assigned to categories" do
    before(:each) do
      # FileModel.purge_cache
      create_category(:heading => "Apple", :path => "the-apple")
      create_category(:heading => "Banana", :path => "banana")
      article = create_article(
          :metadata => { "categories" => "banana, the-apple" })
      get article.abspath
    end
    
    it "should render successfully" do
      last_response.should be_ok
    end
    
    it "should link to each category" do
      body.should have_tag("div.categories", /Filed under/)
      body.should have_tag("div.categories") do |categories|
        categories.should have_tag("a[@href=/banana]", "Banana")
        categories.should have_tag("a[@href=/the-apple]", "Apple")
      end
    end
  end
  
  describe "with parent" do
    before(:each) do
      @category = create_category(:path => "topic")
      article = create_article(:path => "topic/article")
      get article.abspath
    end
    
    it "should link to parent in breadcrumb" do
      body.should have_tag(
          "div.breadcrumb/a[@href=#{@category.abspath}]", @category.heading)
    end
    
    it "should contain parent name in page title" do
      body.should_not have_tag("title", /My blog/)
      body.should have_tag("title", /- My category$/)
    end
  end
end

describe "page" do
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
  end

  after(:each) do
    remove_fixtures
    FileModel.purge_cache
  end
  
  it_should_behave_like "page with menus"
  
  describe "that doesn't exist" do
    it "should return 404 if page not found" do
      get "/no-such-page"
      last_response.should_not be_ok
    end
  end
  
  describe "that exists" do
    before(:each) do
      @description = "Page about stuff"
      @keywords = "things, stuff"
      @content = "Page content"
      @category = create_category(
          :content => "# My category\n\n#{@content}",
          :metadata => {
            "description" => @description,
            "keywords" => @keywords
          })
      @article = create_category(
          :path => "another-page",
          :heading => "Categorised",
          :metadata => { :categories => @category.path },
          :content => "Article content")
      @article2 = create_article(
          :heading => "Second article", :path => "second-article")
      get @category.abspath
    end

    it_should_behave_like "page with meta tags"

    it "should render successfully" do
      last_response.should be_ok
    end
    
    it "should display the heading" do
      body.should have_tag("h1", @category.heading)
    end

    it "should display the content" do
      body.should have_tag("p", @content)
    end

    it "should display links to relevant pages" do
      body.should have_tag(
          "h3 a[@href='#{@article.abspath}']", /^\s*#{@article.heading}$/)
      body.should_not have_tag("h3", @article2.heading)
    end
    
    it "should not include Disqus comments by default" do
      body.should_not have_tag('#disqus_thread')
    end
  end
  
  describe "that is configured to show Disqus comments" do
    before(:each) do
      stub_config_key("disqus_short_name", "mysite")
      @category = create_category
      get @category.abspath
    end
    
    it "should display Disqus comments" do
      body.should have_tag('#disqus_thread')
      body.should have_tag('script[@src*="mysite/embed.js"]')
    end
  end
end

describe "attachments" do
  include ModelFactory
  include RequestSpecHelper

  def create_attachment
    stub_configuration
    create_content_directories
    path = File.join(Nesta::Configuration.attachment_path, "test.txt")
    File.open(path, "w") { |file| file.write("I'm a test attachment") }
  end
  
  before(:each) do
    create_attachment
    get "/attachments/test.txt"
  end
  
  after(:each) do
    remove_fixtures
    FileModel.purge_cache
  end
  
  it "should be served successfully" do
    last_response.should be_ok
  end
  
  it "should be sent to the client" do
    body.should include("I'm a test attachment")
  end
  
  it "should set the appropriate MIME type" do
    last_response.headers["Content-Type"].should == "text/plain"
  end
end
