require File.join(File.dirname(__FILE__), "spec_helper")

describe "page with category links", :shared => true do
  it "should link to each category" do
    body.should have_tag('#sidebar li a[@href=/my-category]', "My category")
  end
end

describe "layout" do
  include ModelFactory
  
  it "should include GA JavaScript" do
    stub_config_key("google_analytics_code", "UA-1234")
    stub_configuration
    get_it "/"
    body.should have_tag("script", /_getTracker\("UA-1234"\)/)
  end
end

describe "home page" do
  include ModelFactory
  
  it_should_behave_like "page with category links"
  
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
  
  it "should link to site title in h1 tag" do
    body.should have_tag("h1 a[@href=/]", "My blog")
  end
  
  it "should display site subheading in h1 tag" do
    body.should have_tag("h1 small", /about stuff/)
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
  
  it_should_behave_like "page with category links"
  
  before(:each) do
    stub_configuration
    create_category
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

  it "should display the date" do
    body.should have_tag("#date", @date)
  end
  
  it "should display the content" do
    body.should have_tag("p", "Content goes here")
  end
end

describe "category" do
  include ModelFactory
  
  it_should_behave_like "page with category links"
  
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
    body.should have_tag("h2 a[@href=/articles/my-article]", "Categorised")
    body.should_not have_tag("h2", "Second article")
  end
end
