require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('model_factory', File.dirname(__FILE__))

describe "page with keyword and description", :shared => true do
  it "should set the keywords meta tag" do
    do_get
    body.should have_tag("meta[@name=keywords][@content='#{@keywords}']")
  end

  it "should set description meta tag" do
    do_get
    body.should have_tag("meta[@name=description][@content='#{@description}']")
  end
end

describe "page that can display menus", :shared => true do
  it "should not display menu by default" do
    do_get
    body.should_not have_tag("#sidebar ul.menu")
  end

  describe "and simple menu configured" do
    before(:each) do
      create_menu(@category.path)
    end

    it "should link to top level menu items" do
      do_get
      body.should have_tag(
        "ul.menu a[@href=#{@category.abspath}]", Regexp.new(@category.heading))
    end
  end
  
  describe "and nested menu configured" do
    before(:each) do
      @level2 = create_category(:path => "level-2", :heading => "Level 2")
      @level3 = create_category(:path => "level-3", :heading => "Level 3")
      text = <<-EOF
#{@category.abspath}
  #{@level2.abspath}
    #{@level3.abspath}
      EOF
      create_menu(text)
    end

    it "should display first level of nested sub menus" do
      do_get
      body.should have_tag("ul.menu li ul li a", Regexp.new(@level2.heading))
    end

    it "should not display nested menus to arbitrary depth" do
      do_get
      body.should_not have_tag("ul.menu li ul li ul")
    end
  end
end

describe "The layout" do
  include ConfigSpecHelper
  include ModelFactory
  include RequestSpecHelper
  
  it "should not include GA JavaScript by default" do
    stub_configuration
    get "/"
    body.should_not have_tag("script", /'_setAccount', 'UA-1234'/)
  end
  
  it "should include GA JavaScript if configured" do
    stub_config_key('google_analytics_code', 'UA-1234', :rack_env => true)
    stub_configuration
    get '/'
    body.should have_tag('script', /'_setAccount', 'UA-1234'/)
  end
end

describe "The home page" do
  include ConfigSpecHelper
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
    template_path = File.expand_path(
        'templates', File.dirname(File.dirname(__FILE__)))
    create_category(
      :path => 'index',
      :ext => :haml,
      :heading => 'Home',
      :content => File.read(File.join(template_path, 'index.haml'))
    )
    create_category
  end
  
  after(:each) do
    remove_fixtures
    Nesta::FileModel.purge_cache
  end

  def do_get
    get "/"
  end
  
  describe "when categories exist" do
    before(:each) do
      @category = create_category
    end
  
    it_should_behave_like "page that can display menus"
  end
  
  it "should render successfully" do
    do_get
    last_response.should be_ok
  end
  
  it "should display site title in hgroup tag" do
    pending "Hpricot doesn't support HTML5"
    body.should have_tag('hgroup h1', /My blog/)
  end
  
  it "should display site subtitle in hgroup tag" do
    pending "Hpricot doesn't support HTML5"
    do_get
    body.should have_tag('hgroup h2', /about stuff/)
  end
  
  describe "when articles have no summary" do
    before(:each) do
      create_article
      do_get
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
      do_get
    end
    
    it "should display link to article in h2 tag" do
      body.should have_tag(
          "h1 a[@href=#{@article.abspath}]", /^\s*#{@article.heading}$/)
    end
    
    it "should display article summary if available" do
      body.should have_tag('p', @summary.split('\n\n').first)
    end
    
    it "should display read more link" do
      body.should have_tag("a[@href=#{@article.abspath}]", @read_more)
    end
  end
end

describe "An article" do
  include ConfigSpecHelper
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
    @date = '07 September 2009'
    @keywords = 'things, stuff'
    @description = 'Page about stuff'
    @summary = 'Multiline\n\nsummary'
    @article = create_article(:metadata => {
      'date' => @date.gsub('September', 'Sep'),
      'description' => @description,
      'keywords' => @keywords,
      'summary' => @summary
    })
  end
  
  after(:each) do
    remove_fixtures
    Nesta::FileModel.purge_cache
  end
  
  def do_get
    get @article.abspath
  end

  it_should_behave_like "page with keyword and description"

  describe "when categories exist" do
    before(:each) do
      @category = create_category
    end
  
    it_should_behave_like "page that can display menus"
  end

  it "should render successfully" do
    do_get
    last_response.should be_ok
  end

  it "should display the heading" do
    do_get
    body.should have_tag('h1', 'My article')
  end

  it "should use heading for title tag" do
    do_get
    body.should have_tag('title', 'My article - My blog')
  end

  it "should display the date" do
    do_get
    body.should have_tag('time', @date)
  end

  it "should display the content" do
    do_get
    body.should have_tag('p', 'Content goes here')
  end
  
  describe "that is assigned to categories" do
    before(:each) do
      create_category(:heading => 'Apple', :path => 'the-apple')
      @category = create_category(:heading => 'Banana', :path => 'banana')
      @article = create_article(
        :path => "#{@category.path}/article",
        :metadata => { 'categories' => 'banana, the-apple' }
      )
    end
    
    it "should render successfully" do
      do_get
      last_response.should be_ok
    end
    
    it "should link to each category" do
      pending "Hpricot doesn't support HTML5"
      do_get
      body.should have_tag("nav.categories") do |categories|
        categories.should have_tag("a[@href=/banana]", "Banana")
        categories.should have_tag("a[@href=/the-apple]", "Apple")
      end
    end

    it "should link to a category in breadcrumb" do
      pending "Hpricot doesn't support HTML5"
      do_get
      body.should have_tag(
          "nav.breadcrumb/a[@href=#{@category.abspath}]", @category.heading)
    end
    
    it "should contain category name in page title" do
      do_get
      body.should_not have_tag("title", /My blog/)
      body.should have_tag("title", /- #{@category.heading}$/)
    end
  end
end

describe "A page" do
  include ConfigSpecHelper
  include ModelFactory
  include RequestSpecHelper
  
  before(:each) do
    stub_configuration
  end

  after(:each) do
    remove_fixtures
    Nesta::FileModel.purge_cache
  end
  
  def do_get
    get @category.abspath
  end

  describe "that doesn't exist" do
    it "should render the 404 page" do
      get "/no-such-page"
      last_response.should_not be_ok
    end
  end
  
  describe "that has meta data" do
    before(:each) do
      @title = 'Different title'
      @content = "Page content"
      @description = "Page about stuff"
      @keywords = "things, stuff"
      @category = create_category(
        :content => "# My category\n\n#{@content}",
        :metadata => {
          'title' => @title,
          'description' => @description,
          'keywords' => @keywords
        }
      )
    end

    it_should_behave_like "page with keyword and description"
    it_should_behave_like "page that can display menus"

    it "should render successfully" do
      do_get
      last_response.should be_ok
    end
    
    it "should display the heading" do
      do_get
      body.should have_tag('h1', @category.heading)
    end

    it "should use title metadata to set heading" do
      do_get
      body.should have_tag('title', @title)
    end

    it "should display the content" do
      do_get
      body.should have_tag("p", @content)
    end

    describe "with associated pages" do
      before(:each) do
        @category1 = create_category(
          :path => 'category1',
          :heading => 'Category 1',
          :metadata => {
            'categories' => 'category-prefix/my-category:-1'
          }
        )
        @category2 = create_category(
          :path => 'category2',
          :heading => 'Category 2',
          :metadata => {
            'categories' => 'category-prefix/my-category:1'
          }
        )
      end

      it "should list highest priority pages at the top" do
        do_get
        body.should have_tag('li:nth-child(1) h1 a', 'Category 2')
        body.should have_tag('li:nth-child(2) h1 a', 'Category 1')
      end
    end

    describe "with associated articles" do
      before(:each) do
        @article = create_article(
          :path => "another-page",
          :heading => "Categorised",
          :metadata => { :categories => @category.path },
          :content => "Article content"
        )
        @article2 = create_article(
          :path => "second-article", :heading => "Second article")
      end

      it "should display links to articles" do
        do_get
        body.should have_tag(
            "h1 a[@href='#{@article.abspath}']", /^\s*#{@article.heading}$/)
        body.should_not have_tag("h3", @article2.heading)
      end
    end

    it "should not include Disqus comments by default" do
      do_get
      body.should_not have_tag('#disqus_thread')
    end
  end
  
  describe "that is configured to show Disqus comments" do
    before(:each) do
      stub_config_key("disqus_short_name", "mysite")
      @category = create_category
    end
    
    it "should display Disqus comments" do
      do_get
      body.should have_tag('#disqus_thread')
      body.should have_tag('script[@src*="mysite.disqus.com/embed.js"]')
    end
  end
end

describe "A Haml page" do
  include ConfigSpecHelper
  include ModelFactory
  include RequestSpecHelper

  before(:each) do
    stub_configuration
  end

  after(:each) do
    remove_fixtures
    Nesta::FileModel.purge_cache
  end

  it "should be able to access helper methods" do
    create_page(
      :path => "a-page",
      :ext => :haml,
      :content => "%div= format_date(Date.new(2010, 11, 23))"
    )
    get "/a-page"
    body.should have_tag("div", "23 November 2010")
  end

  it "should access helpers when rendering articles on a category page" do
    category = create_page(
      :path => "a-page",
      :heading => "First heading",
      :content => "Blah blah"
    )
    create_article(
      :path => "an-article",
      :ext => :haml,
      :heading => "First heading",
      :metadata => { :categories => category.path },
      :content => "%h1 Second heading\n\n%div= format_date(Date.new(2010, 11, 23))"
    )
    get "/a-page"
    body.should have_tag("div", "23 November 2010")
  end
end

describe "attachments" do
  include ConfigSpecHelper
  include ModelFactory
  include RequestSpecHelper

  def create_attachment
    stub_configuration
    create_content_directories
    path = File.join(Nesta::Config.attachment_path, "test.txt")
    File.open(path, "w") { |file| file.write("I'm a test attachment") }
  end
  
  before(:each) do
    create_attachment
    get "/attachments/test.txt"
  end
  
  after(:each) do
    remove_fixtures
    Nesta::FileModel.purge_cache
  end
  
  it "should be served successfully" do
    last_response.should be_ok
  end
  
  it "should be sent to the client" do
    body.should include("I'm a test attachment")
  end
  
  it "should set the appropriate MIME type" do
    last_response.headers["Content-Type"].should =~ Regexp.new("^text/plain")
  end
end
