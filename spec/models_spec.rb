require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('model_factory', File.dirname(__FILE__))

module ModelMatchers
  class HavePage
    def initialize(path)
      @category = path
    end

    def matches?(article)
      @article = article
      article.categories.map { |c| c.path }.include?(@category)
    end

    def failure_message
      "expected '#{@article.path}' to be assigned to #{@category}"
    end

    def negative_failure_message
      "'#{@article.path}' should not be assigned to #{@category}"
    end
  end

  def be_in_category(path)
    HavePage.new(path)
  end
end

shared_context "Page testing" do
  include Webrat::Matchers

  def create_page(options)
    super(options.merge(ext: @extension))
  end

  before(:each) do
    stub_configuration
  end

  after(:each) do
    remove_temp_directory
    Nesta::FileModel.purge_cache
  end
end

shared_examples_for "Page" do
  include ModelFactory
  include ModelMatchers

  it "should be findable" do
    create_page(heading: 'Apple', path: 'the-apple')
    Nesta::Page.find_all.should have(1).item
  end

  it "should return the filename for a path" do
    create_page(heading: 'Banana', path: 'banana')
    Nesta::Page.find_file_for_path('banana').should =~ /banana.#{@extension}$/
  end

  it "should return nil for files that don't exist" do
    Nesta::Page.find_file_for_path('foobar').should be_nil
  end

  it "should find by path" do
    create_page(heading: 'Banana', path: 'banana')
    Nesta::Page.find_by_path('banana').heading.should == 'Banana'
  end

  it "should find index page by path" do
    create_page(heading: 'Banana', path: 'banana/index')
    Nesta::Page.find_by_path('banana').heading.should == 'Banana'
  end

  it "should respond to #parse_metadata, returning hash of key/value" do
    page = create_page(heading: 'Banana', path: 'banana')
    metadata = page.parse_metadata('My key: some value')
    metadata['my key'].should == 'some value'
  end

  it "should be parseable if metadata is invalid" do
    dodgy_metadata = "Key: value\nKey without value\nAnother key: value"
    create_page(heading: 'Banana', path: 'banana') do |path|
      text = File.read(path)
      File.open(path, 'w') do |file|
        file.puts(dodgy_metadata)
        file.write(text)
      end
    end
    Nesta::Page.find_by_path('banana')
  end

  describe "for home page" do
    it "should set title to heading" do
      create_page(heading: 'Home', path: 'index')
      Nesta::Page.find_by_path('/').title.should == 'Home'
    end

    it "should respect title metadata" do
      create_page(path: 'index', metadata: { 'title' => 'Specific title' })
      Nesta::Page.find_by_path('/').title.should == 'Specific title'
    end

    it "should set title to site title by default" do
      create_page(path: 'index')
      Nesta::Page.find_by_path('/').title.should == 'My blog'
    end

    it "should set permalink to empty string" do
      create_page(path: 'index')
      Nesta::Page.find_by_path('/').permalink.should == ''
    end

    it "should set abspath to /" do
      create_page(path: 'index')
      Nesta::Page.find_by_path('/').abspath.should == '/'
    end
  end

  it "should provide metadata defaults" do
    create_page(:path => 'meta1')
    Nesta::Page.find_by_path('meta1').metadata('nonexistant', :default => 'foo').should == 'foo'
  end

  it "should provide recursive metadata search" do
    create_page(:path => 'meta', :metadata => {'foo' => 'bar'})
    create_page(:path => 'meta/page')
    Nesta::Page.find_by_path('meta/page').metadata('foo').should be_nil
    Nesta::Page.find_by_path('meta/page').metadata('foo', :recursive => true).should == 'bar'
  end

  it "should not find nonexistent page" do
    Nesta::Page.find_by_path("no-such-page").should be_nil
  end

  it "should ensure file exists on instantiation" do
    lambda {
      Nesta::Page.new("no-such-file")
    }.should raise_error(Sinatra::NotFound)
  end

  it "should reload cached files when modified" do
    create_page(path: "a-page", heading: "Version 1")
    now = Time.now
    File.stub(:mtime).and_return(now - 1)
    Nesta::Page.find_by_path("a-page")
    create_page(path: "a-page", heading: "Version 2")
    File.stub(:mtime).and_return(now)
    Nesta::Page.find_by_path("a-page").heading.should == "Version 2"
  end

  it "should have default priority of 0 in category" do
    page = create_page(metadata: { 'categories' => 'some-page' })
    page.priority('some-page').should == 0
    page.priority('another-page').should be_nil
  end

  it "should read priority from category metadata" do
    page = create_page(metadata: {
      'categories' => ' some-page:1, another-page , and-another :-1 '
    })
    page.priority('some-page').should == 1
    page.priority('another-page').should == 0
    page.priority('and-another').should == -1
  end

  describe "with assigned pages" do
    before(:each) do
      @category = create_category
      create_article(heading: 'Article 1', path: 'article-1')
      create_article(
        heading: 'Article 2',
        path: 'article-2',
        metadata: {
          'date' => '30 December 2008',
          'categories' => @category.path
        }
      )
      @article = create_article(
        heading: 'Article 3',
        path: 'article-3',
        metadata: {
          'date' => '31 December 2008',
          'categories' => @category.path
        }
      )
      @category1 = create_category(
        path: 'category-1',
        heading: 'Category 1',
        metadata: { 'categories' => @category.path }
      )
      @category2 = create_category(
        path: 'category-2',
        heading: 'Category 2',
        metadata: { 'categories' => @category.path }
      )
      @category3 = create_category(
        path: 'category-3',
        heading: 'Category 3',
        metadata: { 'categories' => "#{@category.path}:1" }
      )
    end

    it "should find articles" do
      @category.articles.should have(2).items
    end

    it "should order articles by reverse chronological order" do
      @category.articles.first.path.should == @article.path
    end

    it "should find pages" do
      @category.pages.should have(3).items
    end

    it "should sort pages by priority" do
      @category.pages.index(@category3).should == 0
    end

    it "should order pages by heading if priority not set" do
      pages = @category.pages
      pages.index(@category1).should < pages.index(@category2)
    end

    it "should not find pages scheduled in the future" do
      future_date = (Time.now + 172800).strftime("%d %B %Y")
      article = create_article(heading: "Article 4",
                               path: "foo/article-4",
                               metadata: { "date" => future_date })
      Nesta::Page.find_articles.detect{|a| a == article}.should be_nil
    end
  end

  describe "with pages in draft" do
    before(:each) do
      @category = create_category
      @draft = create_page(heading: 'Forthcoming content',
                           path: 'foo/in-draft',
                           metadata: {
        'categories' => @category.path,
        'flags' => 'draft'
      })
      Nesta::App.stub(:production?).and_return(true)
    end

    it "should not find assigned drafts" do
      @category.pages.should_not include(@draft)
    end

    it "should not find drafts by path" do
      Nesta::Page.find_by_path('foo/in-draft').should be_nil
    end
  end

  describe "when finding articles" do
    before(:each) do
      create_article(heading: "Article 1", path: "article-1")
      create_article(heading: "Article 2",
                     path: "article-2",
                     metadata: { "date" => "31 December 2008" })
      create_article(heading: "Article 3",
                     path: "foo/article-3",
                     metadata: { "date" => "30 December 2008" })
    end

    it "should only find pages with dates" do
      articles = Nesta::Page.find_articles
      articles.size.should > 0
      Nesta::Page.find_articles.each { |page| page.date.should_not be_nil }
    end

    it "should return articles in reverse chronological order" do
      article1, article2 = Nesta::Page.find_articles[0..1]
      article1.date.should > article2.date
    end
  end

  it "should be able to find parent page" do
    category = create_category(path: 'parent')
    article = create_article(path: 'parent/child')
    article.parent.should == category
  end

  describe "(with deep index page)" do
    it "should be able to find index parent" do
      home = create_category(path: 'index', heading: 'Home')
      category = create_category(path: 'parent')
      category.parent.should == home
      home.parent.should be_nil
    end

    it "should be able to find parent of index" do
      category = create_category(path: "parent")
      index = create_category(path: "parent/child/index")
      index.parent.should == category
    end

    it "should be able to find permalink of index" do
      index = create_category(path: "parent/child/index")
      index.permalink.should == 'child'
    end
  end

  describe "(with missing nested page)" do
    it "should consider grandparent to be parent" do
      grandparent = create_category(path: 'grandparent')
      child = create_category(path: 'grandparent/parent/child')
      child.parent.should == grandparent
    end

    it "should consider grandparent home page to be parent" do
      home = create_category(path: 'index')
      child = create_category(path: 'parent/child')
      child.parent.should == home
    end
  end

  describe "when assigned to categories" do
    before(:each) do
      create_category(heading: "Apple", path: "the-apple")
      create_category(heading: "Banana", path: "banana")
      @article = create_article(
          metadata: { "categories" => "banana, the-apple" })
    end

    it "should be possible to list the categories" do
      @article.categories.should have(2).items
      @article.should be_in_category("the-apple")
      @article.should be_in_category("banana")
      @article.should_not be_in_category("orange")
    end

    it "should sort categories by link text" do
      create_category(heading: "Orange",
                      metadata: { "link text" => "A citrus fruit" },
                      path: "orange")
      article = create_article(metadata: { "categories" => "apple, orange" })
      @article.categories.first.link_text.should == "Apple"
      article.categories.first.link_text.should == "A citrus fruit"
    end

    it "should not be assigned to non-existant category" do
      delete_page(:category, "banana", @extension)
      @article.should_not be_in_category("banana")
    end
  end

  it "should set parent to nil when at root" do
    create_category(path: "top-level").parent.should be_nil
  end

  describe "when not assigned to category" do
    it "should have empty category list" do
      article = create_article
      Nesta::Page.find_by_path(article.path).categories.should be_empty
    end
  end

  describe "with no content" do
    it "should produce no HTML output" do
      create_article do |path|
        file = File.open(path, 'w')
        file.close
      end
      Nesta::Page.find_all.first.to_html.should match(/^\s*$/)
    end
  end

  describe "without metadata" do
    before(:each) do
      create_article
      @article = Nesta::Page.find_all.first
    end

    it "should use default layout" do
      @article.layout.should == :layout
    end

    it "should use default template" do
      @article.template.should == :page
    end

    it "should parse heading correctly" do
      @article.to_html.should have_selector("h1", content: "My article")
    end

    it "should use heading as link text" do
      @article.link_text.should == "My article"
    end

    it "should have default read more link text" do
      @article.read_more.should == "Continue reading"
    end

    it "should not have description" do
      @article.description.should be_nil
    end

    it "should not have keywords" do
      @article.keywords.should be_nil
    end
  end

  describe "with metadata" do
    before(:each) do
      @layout = 'my_layout'
      @template = 'my_template'
      @date = '07 September 2009'
      @keywords = 'things, stuff'
      @description = 'Page about stuff'
      @summary = 'Multiline\n\nsummary'
      @read_more = 'Continue at your leisure'
      @skillz = 'ruby, guitar, bowstaff'
      @link_text = 'Link to stuff page'
      @article = create_article(metadata: {
        'date' => @date.gsub('September', 'Sep'),
        'description' => @description,
        'flags' => 'draft, orange',
        'keywords' => @keywords,
        'layout' => @layout,
        'read more' => @read_more,
        'skillz' => @skillz,
        'summary' => @summary,
        'template' => @template,
        'link text' => @link_text,
      })
    end

    it "should override default layout" do
      @article.layout.should == @layout.to_sym
    end

    it "should override default template" do
      @article.template.should == @template.to_sym
    end

    it "should set permalink to basename of filename" do
      @article.permalink.should == 'my-article'
    end

    it "should set path from filename" do
      @article.path.should == 'article-prefix/my-article'
    end

    it "should retrieve heading" do
      @article.heading.should == 'My article'
    end

    it "should be possible to convert an article to HTML" do
      @article.to_html.should have_selector("h1", content: "My article")
    end

    it "should not include metadata in the HTML" do
      @article.to_html.should_not have_selector("p:contains('Date')")
    end

    it "should not include heading in body markup" do
      @article.body_markup.should_not include("My article")
    end

    it "should not include heading in body" do
      @article.body.should_not have_selector("h1", content: "My article")
    end

    it "should retrieve description from metadata" do
      @article.description.should == @description
    end

    it "should retrieve keywords from metadata" do
      @article.keywords.should == @keywords
    end

    it "should retrieve date published from metadata" do
      @article.date.strftime("%d %B %Y").should == @date
    end

    it "should retrieve read more link from metadata" do
      @article.read_more.should == @read_more
    end

    it "should retrieve summary text from metadata" do
      @article.summary.should match(/#{@summary.split('\n\n').first}/)
    end

    it "should treat double newline chars as paragraph break in summary" do
      @article.summary.should match(/#{@summary.split('\n\n').last}/)
    end

    it "should allow access to metadata" do
      @article.metadata('skillz').should == @skillz
    end

    it "should allow access to flags" do
      @article.should be_flagged_as('draft')
      @article.should be_flagged_as('orange')
    end

    it "should know whether or not it's a draft" do
      @article.should be_draft
    end

    it "should allow link text to be specified explicitly" do
      @article.link_text.should == @link_text
    end
  end

  describe "when checking last modification time" do
    before(:each) do
      create_article
      @article = Nesta::Page.find_all.first
    end

    it "should check filesystem" do
      mock_file_stat(:should_receive, @article.filename, "3 January 2009")
      @article.last_modified.should == Time.parse("3 January 2009")
    end
  end

  describe "with no heading" do
    before(:each) do
      @no_heading_page = create_page(path: 'page-with-no-heading')
    end

    it "should raise a HeadingNotSet exception if you call heading" do
      lambda do
        @no_heading_page.heading
      end.should raise_error(Nesta::HeadingNotSet, /page-with-no-heading/);
    end

    it "should raise a LinkTextNotSet exception if you call link_text" do
      lambda do
        @no_heading_page.link_text
      end.should raise_error(Nesta::LinkTextNotSet, /page-with-no-heading/);
    end
  end
end

describe "All types of page" do
  include ModelFactory

  include_context "Page testing"

  it "should still return top level menu items" do
    # Page.menu_items is deprecated; we're keeping it for the moment so
    # that we don't break themes or code in a local app.rb (just yet).
    page1 = create_category(path: "page-1")
    page2 = create_category(path: "page-2")
    create_menu([page1.path, page2.path].join("\n"))
    Nesta::Page.menu_items.should == [page1, page2]
  end
end

describe "Markdown page" do
  include ModelFactory

  before(:each) do
    @extension = :mdown
  end

  include_context "Page testing"
  it_should_behave_like "Page"

  it "should set heading from first h1 tag" do
    page = create_page(
      path: "a-page",
      heading: "First heading",
      content: "# Second heading"
    )
    page.heading.should == "First heading"
  end

  it "should ignore trailing # characters in headings" do
    article = create_article(heading: 'With trailing #')
    article.heading.should == 'With trailing'
  end
end

describe "Haml page" do
  include ModelFactory

  before(:each) do
    @extension = :haml
  end

  include_context "Page testing"
  it_should_behave_like "Page"

  it "should set heading from first h1 tag" do
    page = create_page(
      path: "a-page",
      heading: "First heading",
      content: "%h1 Second heading"
    )
    page.heading.should == "First heading"
  end

  it "should wrap <p> tags around one line summary text" do
    page = create_page(
      path: "a-page",
      heading: "First para",
      metadata: { "Summary" => "Wrap me" }
    )
    page.summary.should include("<p>Wrap me</p>")
  end

  it "should wrap <p> tags around multiple lines of summary text" do
    page = create_page(
      path: "a-page",
      heading: "First para",
      metadata: { "Summary" => 'Wrap me\nIn paragraph tags' }
    )
    page.summary.should include("<p>Wrap me</p>")
    page.summary.should include("<p>In paragraph tags</p>")
  end
end

describe "Textile page" do
  include ModelFactory

  before(:each) do
    @extension = :textile
  end

  include_context "Page testing"
  it_should_behave_like "Page"

  it "should set heading from first h1 tag" do
    page = create_page(
      path: "a-page",
      heading: "First heading",
      content: "h1. Second heading"
    )
    page.heading.should == "First heading"
  end
end

describe "Menu" do
  include ModelFactory

  before(:each) do
    stub_configuration
    @page = create_page(path: "page-1")
  end

  after(:each) do
    remove_temp_directory
    Nesta::FileModel.purge_cache
  end

  it "should find top level menu items" do
    text = [@page.path, "no-such-page"].join("\n")
    create_menu(text)
    Nesta::Menu.top_level.should == [@page]
  end

  it "should find all items in the menu" do
    create_menu(@page.path)
    Nesta::Menu.full_menu.should == [@page]
    Nesta::Menu.for_path('/').should == [@page]
  end

  describe "with nested sub menus" do
    before(:each) do
      (2..6).each do |i|
        instance_variable_set("@page#{i}", create_page(path: "page-#{i}"))
      end
      text = <<-EOF
#{@page.path}
  #{@page2.path}
    #{@page3.path}
    #{@page4.path}
#{@page5.path}
  #{@page6.path}
      EOF
      create_menu(text)
    end

    it "should return top level menu items" do
      Nesta::Menu.top_level.should == [@page, @page5]
    end

    it "should return full tree of menu items" do
      Nesta::Menu.full_menu.should ==
        [@page, [@page2, [@page3, @page4]], @page5, [@page6]]
    end

    it "should return part of the tree of menu items" do
      Nesta::Menu.for_path(@page2.path).should == [@page2, [@page3, @page4]]
    end

    it "should deem menu for path that isn't in menu to be nil" do
      Nesta::Menu.for_path('wibble').should be_nil
    end
  end
end
