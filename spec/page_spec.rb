require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('model_factory', File.dirname(__FILE__))

shared_examples_for "page with keyword and description" do
  it "should set the keywords meta tag" do
    do_get
    assert_xpath "//meta[@name='keywords'][@content='#{@keywords}']"
  end

  it "should set description meta tag" do
    do_get
    assert_xpath "//meta[@name='description'][@content='#{@description}']"
  end
end

shared_examples_for "page that can display menus" do
  it "should not display menu by default" do
    do_get
    last_response.should be_ok
    assert_not_selector "#sidebar ul.menu"
  end

  describe "and simple menu configured" do
    before(:each) do
      create_menu(@category.path)
    end

    it "should link to top level menu items" do
      do_get
      link_text = @category.link_text
      href = @category.abspath
      assert_selector "ul.menu a[@href$='#{href}']:contains('#{link_text}')"
    end
  end

  describe "and nested menu configured" do
    before(:each) do
      @level2 = create_category(path: "level-2", heading: "Level 2",
                                metadata: {'link text' => "Level 2 link"})
      @level3 = create_category(path: "level-3", heading: "Level 3")
      text = <<-EOF
#{@category.abspath}
  #{@level2.abspath}
    #{@level3.abspath}
      EOF
      create_menu(text)
    end

    it "should display first level of nested sub menus" do
      do_get
      assert_selector "ul.menu li ul li a:contains('#{@level2.link_text}')"
    end

    it "should not display nested menus to arbitrary depth" do
      do_get
      last_response.should be_ok
      assert_not_selector "ul.menu li ul li ul"
    end
  end

  describe "and menu links to home page" do
    before(:each) do
      text = <<-EOF
/
  #{@category.abspath}
EOF
      create_menu(text)
      template_path = File.expand_path(
        'templates', File.dirname(File.dirname(__FILE__)))
      @default_homepage_content = File.read(File.join(template_path,
                                                      'index.haml'))
    end

    it "should use 'Home' as the home page link if not otherwise specified" do
      create_page(
        path: 'index',
        ext: :haml,
        content: @default_homepage_content)
      do_get
      assert_selector "ul.menu a[@href='/']:contains('Home')"
    end

    it "should use the heading if it exists" do
      create_page(
        path: 'index',
        ext: :haml,
        heading: 'My heading',
        content: @default_homepage_content)
      do_get
      assert_selector "ul.menu a[@href='/']:contains('My heading')"
    end

    it "should use the link text if specified" do
      create_page(
        path: 'index',
        ext: :haml,
        heading: 'My heading',
        content: @default_homepage_content,
        metadata: {'link text'=>'My link text'})
      do_get
      assert_selector "ul.menu a[@href='/']:contains('My link text')"
    end
  end
end

describe "The layout" do
  include ModelFactory
  include RequestSpecHelper

  it "should not include GA JavaScript by default" do
    stub_configuration
    get "/"
    assert_not_selector "script", content: "'_setAccount', 'UA-1234'"
  end

  it "should include GA JavaScript if configured" do
    stub_config_key('google_analytics_code', 'UA-1234', rack_env: true)
    stub_configuration
    get "/"
    assert_selector 'script', content: "'_setAccount', 'UA-1234'"
  end
end

describe "The home page" do
  include ModelFactory
  include RequestSpecHelper

  before(:each) do
    stub_configuration
    template_path = File.expand_path(
        'templates', File.dirname(File.dirname(__FILE__)))
    create_category(
      path: 'index',
      ext: :haml,
      heading: 'Home',
      content: File.read(File.join(template_path, 'index.haml'))
    )
    create_category
  end

  after(:each) do
    remove_temp_directory
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
    do_get
    assert_selector 'hgroup h1', content: "My blog"
  end

  it "should display site subtitle in hgroup tag" do
    do_get
    assert_selector 'hgroup h2', content: "about stuff"
  end

  describe "when articles have no summary" do
    before(:each) do
      create_article
      do_get
    end

    it "should display full content of article" do
      assert_selector "p", content: "Content goes here"
    end

    it "should not display read more link" do
      last_response.should be_ok
      assert_not_selector "a", content: 'continue'
    end
  end

  describe "when articles have metadata" do
    before(:each) do
      @summary = 'Multiline\n\nsummary'
      @read_more = "Continue at your leisure"
      @article = create_article(metadata: {
        "summary" => @summary,
        "read more" => @read_more
      })
      do_get
    end

    it "should display link to article in h2 tag" do
      link_text = @article.link_text
      href = @article.abspath
      assert_selector "h1 a[@href$='#{href}']:contains('#{link_text}')"
    end

    it "should display article summary if available" do
      assert_selector 'p', content: @summary.split('\n\n').first
    end

    it "should display read more link" do
      assert_selector "a[@href$='#{@article.abspath}']", content: @read_more
    end
  end
end

describe "An article" do
  include ModelFactory
  include RequestSpecHelper

  before(:each) do
    stub_configuration
    @date = '07 September 2009'
    @keywords = 'things, stuff'
    @description = 'Page about stuff'
    @summary = 'Multiline\n\nsummary'
    @link_text = 'Link to page about stuff'
    @article = create_article(metadata: {
      'date' => @date.gsub('September', 'Sep'),
      'description' => @description,
      'keywords' => @keywords,
      'summary' => @summary,
      'link text' => @link_text
    })
  end

  after(:each) do
    remove_temp_directory
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
    assert_selector 'h1', content: 'My article'
  end

  it "should use link text for title tag" do
    do_get
    assert_selector 'title', content: @link_text
  end

  it "should display the date" do
    do_get
    assert_selector 'time', content: @date
  end

  it "should display the content" do
    do_get
    assert_selector 'p', content: 'Content goes here'
  end

  describe "that is assigned to categories" do
    before(:each) do
      create_category(heading: 'Apple', path: 'the-apple')
      @category = create_category(heading: 'Banana', path: 'banana')
      @article = create_article(
        path: "#{@category.path}/article",
        metadata: { 'categories' => 'banana, the-apple' }
      )
    end

    it "should render successfully" do
      do_get
      last_response.should be_ok
    end

    it "should link to each category" do
      do_get
      assert_selector "p.meta a[href='/banana']", content: "Banana"
      assert_selector "p.meta a[href='/the-apple']", content: "Apple"
    end

    it "should link to a category in breadcrumb" do
      do_get
      href = @category.abspath
      link_text = @category.link_text
      assert_selector "nav.breadcrumb a[href='#{href}']", content: link_text
    end

    it "should not include Disqus comments by default" do
      do_get
      last_response.should be_ok
      assert_not_selector '#disqus_thread'
    end
  end

  describe "that is configured to show Disqus comments" do
    before(:each) do
      stub_config_key("disqus_short_name", "mysite")
      @category = create_category
    end

    it "should display Disqus comments" do
      do_get
      assert_selector '#disqus_thread'
      assert_selector 'script[@src*="mysite.disqus.com/embed.js"]'
    end
  end
end

describe "A page" do
  include ModelFactory
  include RequestSpecHelper

  before(:each) do
    stub_configuration
  end

  after(:each) do
    remove_temp_directory
    Nesta::FileModel.purge_cache
  end

  def do_get
    get @category.abspath
  end

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

    it_should_behave_like "page with keyword and description"
    it_should_behave_like "page that can display menus"

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

    it "should display the heading" do
      do_get
      assert_selector 'h1', content: @category.heading
    end

    it "should use title metadata to set heading" do
      do_get
      assert_selector 'title', content: @title
    end

    it "should display the content" do
      do_get
      assert_selector "p", content: @content
    end

    describe "with associated pages" do
      before(:each) do
        @category1 = create_category(
          path: 'category1',
          heading: 'Category 1',
          metadata: {
            'categories' => 'category-prefix/my-category:-1'
          }
        )
        @category2 = create_category(
          path: 'category2',
          heading: 'Category 2',
          metadata: {
            'categories' => 'category-prefix/my-category:1'
          }
        )
      end

      it "should list highest priority pages at the top" do
        do_get
        assert_selector 'li:nth-child(1) h1 a', content: 'Category 2'
        assert_selector 'li:nth-child(2) h1 a', content: 'Category 1'
      end
    end

    describe "with associated articles" do
      before(:each) do
        @article = create_article(
          path: "another-page",
          heading: "Categorised",
          metadata: { categories: @category.path,
                         'link text' => 'Categorised link'},
          content: "Article content"
        )
        @article2 = create_article(
          path: "second-article", heading: "Second article")
      end

      it "should display links to articles" do
        do_get
        href = @article.abspath
        link_text = @article.link_text
        assert_selector "h1 a[@href$='#{href}']", content: link_text
        assert_not_selector "h3", content: @article2.link_text
      end

      it "should display the article heading" do
        do_get
        assert_selector 'h1', content: @articles_heading
      end
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
