require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('model_factory', File.dirname(__FILE__))

describe "A page" do
  include ModelFactory
  include RequestSpecHelper

  describe "that doesn't exist" do
    it "should render the 404 page" do
      get "/no-such-page"
      last_response.should be_not_found
    end
  end

  describe "that has meta data" do
    before(:each) do
      @title = 'Different title'
      @content = "Page content"
      @description = "Page about stuff"
      @keywords = "things, stuff"
      @articles_heading = "Posts about this stuff"
      @category = create_category(
        content: "# My category\n\n#{@content}",
        metadata: {
          'title' => @title,
          'description' => @description,
          'keywords' => @keywords,
          'articles heading' => @articles_heading
        }
      )
    end

    describe "whose URL ends in /" do
      it "should be redirected, removing the slash" do
        get @category.abspath + '/'
        last_response.should be_redirect
      end
    end

    it "should render successfully" do
      do_get
      last_response.should be_ok
    end
  end
end

describe "A Haml page" do
  include ModelFactory
  include RequestSpecHelper

  before(:each) do
    stub_configuration
  end

  after(:each) do
    remove_temp_directory
    Nesta::FileModel.purge_cache
  end

  it "should be able to access helper methods" do
    create_page(
      path: "a-page",
      ext: :haml,
      content: "%div= format_date(Date.new(2010, 11, 23))",
      heading: "A Page"
    )
    get "/a-page"
    assert_selector "div", content: "23 November 2010"
  end

  it "should access helpers when rendering articles on a category page" do
    category = create_page(
      path: "a-page",
      heading: "First heading",
      content: "Blah blah"
    )
    create_article(
      path: "an-article",
      ext: :haml,
      heading: "First heading",
      metadata: { categories: category.path },
      content: "%h1 Second heading\n\n%div= format_date(Date.new(2010, 11, 23))"
    )
    get "/a-page"
    assert_selector "div", content: "23 November 2010"
  end
end

describe "attachments" do
  include ModelFactory
  include RequestSpecHelper

  before(:each) do
    stub_configuration
    create_content_directories
  end

  after(:each) do
    remove_temp_directory
    Nesta::FileModel.purge_cache
  end

  describe "in the attachments folder" do
    before(:each) do
      path = File.join(Nesta::Config.attachment_path, 'test.txt')
      File.open(path, 'w') { |file| file.write("I'm a test attachment") }
    end

    it "should be served successfully" do
      get "/attachments/test.txt"
      last_response.should be_ok
    end

    it "should be sent to the client" do
      get "/attachments/test.txt"
      body.should include("I'm a test attachment")
    end

    it "should set the appropriate MIME type" do
      get "/attachments/test.txt"
      last_response.headers["Content-Type"].should =~ Regexp.new("^text/plain")
    end
  end

  describe "outside the attachments folder" do
    before(:each) do
      path = File.join(Nesta::Config.page_path, 'index.haml')
      File.open(path, 'w') { |file| file.write('%h1 Test page') }
    end

    it "should be directory traversal free" do
      get '/attachments/../pages/index.haml'
      last_response.should_not be_ok
    end
  end
end
