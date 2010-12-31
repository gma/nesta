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

describe "Page", :shared => true do
  include ConfigSpecHelper
  include ModelFactory
  include ModelMatchers

  def create_page(options)
    super(options.merge(:ext => @extension))
  end

  before(:each) do
    stub_configuration
  end
  
  after(:each) do
    remove_fixtures
    Nesta::FileModel.purge_cache
  end
  
  it "should be findable" do
    create_page(:heading => "Apple", :path => "the-apple")
    Nesta::Page.find_all.should have(1).item
  end

  it "should find by path" do
    create_page(:heading => "Banana", :path => "banana")
    Nesta::Page.find_by_path("banana").heading.should == "Banana"
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
    create_page(:path => "a-page", :heading => "Version 1")
    File.stub!(:mtime).and_return(Time.new - 1)
    Nesta::Page.find_by_path("a-page")
    create_page(:path => "a-page", :heading => "Version 2")
    File.stub!(:mtime).and_return(Time.new)
    Nesta::Page.find_by_path("a-page").heading.should == "Version 2"
  end
  
  describe "with assigned pages" do
    before(:each) do
      @category = create_category
      create_article(:heading => "Article 1", :path => "article-1")
      create_article(
        :heading => "Article 2",
        :path => "article-2",
        :metadata => {
          "date" => "30 December 2008",
          "categories" => @category.path
        }
      )
      @article = create_article(
        :heading => "Article 3",
        :path => "article-3",
        :metadata => {
          "date" => "31 December 2008",
          "categories" => @category.path
        }
      )
      create_category(:path => "category-2",
                      :metadata => { "categories" => @category.path })
    end

    it "should find articles" do
      @category.articles.should have(2).items
    end
    
    it "should list most recent articles first" do
      @category.articles.first.path.should == @article.path
    end
    
    it "should find pages" do
      @category.pages.should have(1).item
    end
    
    it "should not find pages scheduled in the future" do
      future_date = (Time.now + 86400).strftime("%d %B %Y")
      article = create_article(:heading => "Article 4",
                               :path => "foo/article-4",
                               :metadata => { "date" => future_date })
      Nesta::Page.find_articles.detect{|a| a == article}.should be_nil
    end
  end
  
  describe "when finding articles" do
    before(:each) do
      create_article(:heading => "Article 1", :path => "article-1")
      create_article(:heading => "Article 2",
                     :path => "article-2",
                     :metadata => { "date" => "31 December 2008" })
      create_article(:heading => "Article 3",
                     :path => "foo/article-3",
                     :metadata => { "date" => "30 December 2008" })
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
  
  describe "when assigned to categories" do
    before(:each) do
      create_category(:heading => "Apple", :path => "the-apple")
      create_category(:heading => "Banana", :path => "banana")
      @article = create_article(
          :metadata => { "categories" => "banana, the-apple" })
    end
    
    it "should be possible to list the categories" do
      @article.categories.should have(2).items
      @article.should be_in_category("the-apple")
      @article.should be_in_category("banana")
    end
    
    it "should sort categories by heading" do
      @article.categories.first.heading.should == "Apple"
    end
    
    it "should not be assigned to non-existant category" do
      delete_page(:category, "banana", @extension)
      @article.should_not be_in_category("banana")
    end
  end
  
  it "should be able to find parent page" do
    category = create_category(:path => "parent")
    article = create_article(:path => "parent/child")
    article.parent.should == category
  end
  
  it "should set parent to nil when at root" do
    create_category(:path => "top-level").parent.should be_nil
  end
  
  describe "when not assigned to category" do
    it "should have empty category list" do
      article = create_article
      Nesta::Page.find_by_path(article.path).categories.should be_empty
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
      @article.to_html.should have_tag("h1", "My article")
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
      @layout = "my_layout"
      @template = "my_template"
      @date = "07 September 2009"
      @keywords = "things, stuff"
      @description = "Page about stuff"
      @summary = 'Multiline\n\nsummary'
      @read_more = "Continue at your leisure"
      @skillz = "ruby, guitar, bowstaff"
      @article = create_article(:metadata => {
        "layout" => @layout,
        "template" => @template,
        "date" => @date.gsub("September", "Sep"),
        "description" => @description,
        "keywords" => @keywords,
        "summary" => @summary,
        "read more" => @read_more,
        "skillz" => @skillz
      })
    end

    it "should override default layout" do
      @article.layout.should == @layout.to_sym
    end
    
    it "should override default template" do
      @article.template.should == @template.to_sym
    end
    
    it "should set permalink from filename" do
      @article.permalink.should == "my-article"
    end
    
    it "should set path from filename" do
      @article.path.should == "article-prefix/my-article"
    end
    
    it "should retrieve heading" do
      @article.heading.should == "My article"
    end
    
    it "should be possible to convert an article to HTML" do
      @article.to_html.should have_tag("h1", "My article")
    end
    
    it "should not include metadata in the HTML" do
      @article.to_html.should_not have_tag("p", /^Date/)
    end
    
    it "should not include heading in body" do
      @article.body.should_not have_tag("h1", "My article")
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
    
    it "should allow arbitrary access to metadata" do
      @article.metadata('skillz').should == @skillz
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
end

describe "All types of page" do
  include ConfigSpecHelper
  include ModelFactory

  before(:each) do
    stub_configuration
  end
  
  after(:each) do
    remove_fixtures
    Nesta::FileModel.purge_cache
  end
  
  it "should still return top level menu items" do
    # Page.menu_items is deprecated; we're keeping it for the moment so
    # that we don't break themes or code in a local app.rb (just yet).
    page1 = create_category(:path => "page-1")
    page2 = create_category(:path => "page-2")
    create_menu([page1.path, page2.path].join("\n"))
    Nesta::Page.menu_items.should == [page1, page2]
  end
end

describe "Markdown page" do
  include ConfigSpecHelper

  before(:each) do
    @extension = :mdown
  end

  it_should_behave_like "Page"

  it "should set heading from first h1 tag" do
    create_page(
      :path => "a-page",
      :heading => "First heading",
      :content => "# Second heading"
    )
    Nesta::Page.find_by_path("a-page").heading.should == "First heading"
  end
end

describe "Haml page" do
  include ConfigSpecHelper

  before(:each) do
    @extension = :haml
  end

  it_should_behave_like "Page"

  it "should set heading from first h1 tag" do
    create_page(
      :path => "a-page",
      :heading => "First heading",
      :content => "%h1 Second heading"
    )
    Nesta::Page.find_by_path("a-page").heading.should == "First heading"
  end
end

describe "Textile page" do
  include ConfigSpecHelper

  before(:each) do
    @extension = :textile
  end

  it_should_behave_like "Page"

  it "should set heading from first h1 tag" do
    create_page(
      :path => "a-page",
      :heading => "First heading",
      :content => "h1. Second heading"
    )
    Nesta::Page.find_by_path("a-page").heading.should == "First heading"
  end
end

describe "Menu" do
  include ConfigSpecHelper
  include ModelFactory

  before(:each) do
    stub_configuration
    @page = create_page(:path => "page-1")
  end

  after(:each) do
    remove_fixtures
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
        instance_variable_set("@page#{i}", create_page(:path => "page-#{i}"))
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
