require File.join(File.dirname(__FILE__), "spec_helper")

describe "layout" do
  include ModelFactory
  
  it "should not include GA JavaScript by default" do
    stub_configuration
    get_it "/"
    body.should_not have_tag("script", /_getTracker\("UA-1234"\)/)
  end
  
  it "should include GA JavaScript if configured" do
    stub_config_key("google_analytics_code", "UA-1234")
    stub_configuration
    get_it "/"
    body.should have_tag("script", /_getTracker\("UA-1234"\)/)
  end
end

describe "home page" do
  include ModelFactory
  
  before(:each) do
    stub_configuration
    create_category
    get_it "/"
  end
  
  after(:each) do
    remove_fixtures
  end

  it "should render successfully" do
    @response.should be_ok
  end
  
  it "should display title in title tag" do
    body.should have_tag("title", "My blog")
  end
  
  it "should display site title in h1 tag" do
    body.should have_tag("h1", /My blog/)
  end
  
  it "should display site subheading in h1 tag" do
    body.should have_tag("h1 small", /about stuff/)
  end
  
  it "should link to each category" do
    body.should have_tag('#sidebar li a[@href=/my-category]', "My category")
  end

  describe "when articles exist" do
    before(:each) do
      @date, @summary = create_article_with_metadata
      get_it "/"
    end

    it "should display link to article in h2 tag" do
      body.should have_tag("h2 a[@href=/articles/my-article]", "My article")
    end
    
    it "should display article summary if available" do
      body.should have_tag("p", @summary)
    end
  end
end

describe "article" do
  include ModelFactory
  
  before(:each) do
    stub_configuration
    @date, @summary = create_article_with_metadata
    get_it "/articles/my-article"
  end

  after(:each) do
    remove_fixtures
  end
  
  it "should render successfully" do
    @response.should be_ok
  end

  it "should display the heading" do
    body.should have_tag("h1", "My article")
  end

  it "should not display category links" do
    body.should_not have_tag("div.breadcrumb div.categories", /filed in/)
  end

  it "should display the date" do
    body.should have_tag("#date", @date)
  end

  it "should display the content" do
    body.should have_tag("p", "Content goes here")
  end
  
  describe "when assigned to categories" do
    before(:each) do
      create_category(:title => "Apple", :permalink => "the-apple")
      create_category(:title => "Banana", :permalink => "banana")
      create_article(:metadata => { "categories" => "banana, the-apple" })
      get_it "/articles/my-article"
    end
    
    it "should render successfully" do
      @response.should be_ok
    end
    
    it "should link to each category" do
      body.should have_tag("div.breadcrumb div.categories", /filed in/)
      body.should have_tag("div.breadcrumb div.categories") do |categories|
        categories.should have_tag("a[@href=/banana]", "Banana")
        categories.should have_tag("a[@href=/the-apple]", "Apple")
      end
    end
  end
end

describe "category" do
  include ModelFactory
  
  before(:each) do
    stub_configuration
    create_category
    create_article(
        :title => "Categorised", :metadata => { :categories => "my-category" })
    create_article(:title => "Second article", :permalink => "second-article")
    get_it "/my-category"
  end
  
  after(:each) do
    remove_fixtures
  end

  it "should render successfully" do
    @response.should be_ok
  end
  
  it "should display the heading" do
    body.should have_tag("h1", "My category")
  end

  it "should display the content" do
    body.should have_tag("p", "Content goes here")
  end
  
  it "should display links to relevant articles" do
    body.should have_tag("h3 a[@href=/articles/my-article]", "Categorised")
    body.should_not have_tag("h3", "Second article")
  end
  
  it "should link to each category" do
    body.should have_tag('#sidebar li a[@href=/my-category]', "My category")
  end
end
