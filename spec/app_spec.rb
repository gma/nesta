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
  end

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
    body.should have_tag("meta[@name=description][@content=great web site]")
  end
  
  it "should set keywords meta tag" do
    body.should have_tag("meta[@name=keywords][@content=home, page]")
  end
  
  it "should link to each category" do
    body.should have_tag('#sidebar li a[@href=/my-category]', "My category")
  end
  
  describe "when articles have no metadata" do
    before(:each) do
      create_article
      @article = Article.find_by_permalink("my-article")
      get "/"
    end
    
    it "should display article heading in h2" do
      body.should have_tag("h2 a[@href=/articles/my-article]", "My article")
    end
    
    it "should display article content if article has no summary" do
      body.should have_tag("p", "Content goes here")
    end
    
    it "should not display read more link if article has no summary" do
      body.should_not have_tag("a", /continue/i)
    end
  end

  describe "when articles have metadata" do
    before(:each) do
      metadata = create_article_with_metadata
      @date = metadata["date"]
      @summary = metadata["summary"]
      @read_more = metadata["read more"]
      get "/"
    end
    
    it "should display link to article in h2 tag" do
      body.should have_tag("h2 a[@href=/articles/my-article]", "My article")
    end
    
    it "should display article summary if available" do
      body.should have_tag("p", @summary.split('\n\n').first)
    end
    
    it "should display read more link if set" do
      body.should have_tag("a[@href=/articles/my-article]", "Continue please")
    end
  end
end

describe "page with meta tags", :shared => true do
  it "should set description meta tag" do
    body.should have_tag("meta[@name=description][@content=#{@description}]")
  end
  
  it "should set the keywords meta tag" do
    body.should have_tag("meta[@name=keywords][@content=#{@keywords}]")
  end
end

describe "article" do
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
    metadata = create_article_with_metadata
    @description = metadata["description"]
    @keywords = metadata["keywords"]
    @date = metadata["date"]
    @summary = metadata["summary"]
    get "/articles/my-article"
  end

  after(:each) do
    remove_fixtures
  end
  
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
  
  describe "when assigned to categories" do
    before(:each) do
      create_category(:title => "Apple", :permalink => "the-apple")
      create_category(:title => "Banana", :permalink => "banana")
      create_article(:metadata => { "categories" => "banana, the-apple" })
      get "/articles/my-article"
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
  
  describe "when has parent" do
    before(:each) do
      create_category
      create_article(:metadata => { "parent" => "my-category" })
      get "/articles/my-article"
    end
    
    it "should link to parent in breadcrumb" do
      body.should have_tag(
          "div.breadcrumb/a[@href=/my-category]", "My category")
    end
    
    it "should contain parent name in page title" do
      body.should_not have_tag("title", /My blog/)
      body.should have_tag("title", /- My category$/)
    end
  end
  
  describe "when has comments" do
    before(:each) do
      create_comment
      @comment = Comment.find_all.first
      get "/articles/my-article"
    end
    
    it "should display comments heading" do
      body.should have_tag("h2", "Comments")
    end
    
    it "should display link to comment author's site" do
      body.should have_tag(
          "ol//a[@href=#{@comment.author_url}][@rel=nofollow]",
          @comment.author)
    end
    
    it "should display comment copy" do
      body.should have_tag("ol//p", "Great article.")
    end
  end

  describe "when page doesn't exist" do
    it "should return 404 if page not found" do
      get "/articles/no-such-article"
      last_response.should_not be_ok
    end
  end
  
end

describe "category" do
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
  end

  after(:each) do
    remove_fixtures
  end

  describe "when category exists" do
    before(:each) do
      @description = "Page about stuff"
      @keywords = "things, stuff"
      create_category(:content => "# My category\n\nCategory content",
                      :metadata => {
                        "description" => @description,
                        "keywords" => @keywords
                      })
      create_article(
          :title => "Categorised",
          :metadata => { :categories => "my-category" },
          :content => "Article content")
      create_article(:title => "Second article", :permalink => "second-article")
      get "/my-category"
    end

    it_should_behave_like "page with meta tags"

    it "should render successfully" do
      last_response.should be_ok
    end

    it "should display the heading" do
      body.should have_tag("h1", "My category")
    end

    it "should display the content" do
      body.should have_tag("p", "Category content")
    end

    it "should display links to relevant articles" do
      body.should have_tag("h3 a[@href=/articles/my-article]", "Categorised")
      body.should_not have_tag("h3", "Second article")
    end

    it "should link to each category" do
      body.should have_tag('#sidebar li a[@href=/my-category]', "My category")
    end
  end

  describe "when page doesn't exist" do
    it "should return 404 if page not found" do
      get "/my-category"
      last_response.should_not be_ok
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
