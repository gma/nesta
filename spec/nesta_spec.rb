require File.join(File.dirname(__FILE__), "spec_helper")

describe "home page" do
  include ArticleFactory
  
  before(:each) do
    Nesta::Configuration.stub!(:configuration).and_return({
      "blog" => { "title" => "My blog", "subheading" => "about stuff" },
      "content" => File.join(File.dirname(__FILE__), ["fixtures"])
    })
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
      create_article
      get_it "/"
    end

    it "should display link to article in h2 tag" do
      body.should have_tag("h2 a[@href=/articles/my-article]", "My article")
    end
  end
end
