require 'test_helper'

describe Nesta::Page do
  include ModelFactory
  include TestConfiguration

  after do
    Nesta::FileModel.purge_cache
    remove_temp_directory
  end

  it 'raises error if instantiated for non existant file' do
    with_temp_content_directory do
      assert_raises(Sinatra::NotFound) do
        Nesta::Page.new('no-such-file')
      end
    end
  end

  describe '.find_by_path' do
    it 'finds model instances by path' do
      with_temp_content_directory do
        page = create(:page)
        assert_equal page.heading, Nesta::Page.find_by_path(page.path).heading
      end
    end

    it 'finds model for index page by path' do
      with_temp_content_directory do
        page = create(:page, path: 'path/index')
        assert_equal page.heading, Nesta::Page.find_by_path('path').heading
      end
    end

    it 'finds model for home page when path is /' do
      with_temp_content_directory do
        create(:page, heading: 'Home', path: 'index')
        assert_equal 'Home', Nesta::Page.find_by_path('/').title
      end
    end

    it 'returns nil if page not found' do
      with_temp_content_directory do
        assert_nil Nesta::Page.find_by_path('no-such-page')
      end
    end

    it 'returns nil for draft pages when running in production'do
      with_temp_content_directory do
        draft = create(:page, metadata: { 'flags' => 'draft' })
        assert Nesta::Page.find_by_path(draft.path), 'should find draft'
        Nesta::App.stub(:production?, true) do
          assert_nil Nesta::Page.find_by_path(draft.path)
        end
      end
    end
  end

  describe '.find_articles 'do
    it "doesn't return articles with a published date in the future" do
      with_temp_content_directory do
        future_date = (Time.now + 172800).strftime('%d %B %Y')
        article = create(:article, metadata: { 'date' => future_date })
        assert_nil Nesta::Page.find_articles.detect { |a| a == article }
      end
    end

    it "doesn't return pages without a date" do
      with_temp_content_directory do
        create(:category)
        create(:article)
        articles = Nesta::Page.find_articles
        assert_equal 1, articles.size
        articles.each { |page| fail 'not an article' if page.date.nil? }
      end
    end

    it 'returns articles in reverse chronological order' do
      with_temp_content_directory do
        create(:article, metadata: { 'date' => '30 December 2008' })
        create(:article, metadata: { 'date' => '31 December 2008' })
        article1, article2 = Nesta::Page.find_articles[0..1]
        assert article1.date > article2.date, 'not reverse chronological order'
      end
    end
  end

  describe '#title' do
    it 'returns page heading by default' do
      with_temp_content_directory do
        page = create(:page, heading: 'Heading')
        assert_equal page.heading, Nesta::Page.find_by_path(page.path).title
      end
    end

    it 'overrides heading with title set in metadata' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'title' => 'Specific title' })
        assert_equal 'Specific title', Nesta::Page.find_by_path(page.path).title
      end
    end

    it 'defaults to site title for home page' do
      stub_config(temp_content.merge('title' => 'Site title')) do
        create(:page, heading: nil, path: 'index')
        assert_equal 'Site title', Nesta::Page.find_by_path('/').title
      end
    end
  end

  describe '#heading' do
    it 'raises error if heading not set' do
      with_temp_content_directory do
        assert_raises Nesta::HeadingNotSet do
          create(:page, heading: nil).heading
        end
      end
    end

    it 'parses Markdown pages returning contents of first # heading' do
      with_temp_content_directory do
        page = create(:page) do |path|
          file = File.open(path, 'w')
          file.write('# Hello Markdown')
          file.close
        end
        assert_equal 'Hello Markdown', page.heading
      end
    end

    it 'parses Textile pages returning contents of first h1. heading' do
      with_temp_content_directory do
        page = create(:page, ext: 'textile') do |path|
          file = File.open(path, 'w')
          file.write('h1. Hello Textile')
          file.close
        end
        assert_equal 'Hello Textile', page.heading
      end
    end

    it 'parases Haml pages returning contents of first %h1 tag' do
      with_temp_content_directory do
        page = create(:page, ext: 'haml') do |path|
          file = File.open(path, 'w')
          file.write('%h1 Hello Haml')
          file.close
        end
        assert_equal 'Hello Haml', page.heading
      end
    end

    it 'ignores subsequent h1 tags' do
      with_temp_content_directory do
        page = create(:page, content: '# Second heading')
        fail 'wrong h1 tag' if page.heading == 'Second heading'
      end
    end

    it 'ignores trailing # characters in Markdown headings' do
      with_temp_content_directory do
        page = create(:page, heading: 'With trailing #')
        assert_equal 'With trailing', page.heading
      end
    end
  end

  describe '#abspath' do
    it 'returns / for home page' do
      with_temp_content_directory do
        create(:page, path: 'index')
        assert_equal '/', Nesta::Page.find_by_path('index').abspath
      end
    end
  end

  describe '#permalink' do
    it 'returns basename of filename' do
      with_temp_content_directory do
        assert_equal 'page', create(:page, path: 'path/to/page').permalink
      end
    end

    it 'returns empty string for home page' do
      with_temp_content_directory do
        home = create(:page, path: 'index')
        assert_equal '', Nesta::Page.find_by_path(home.path).permalink
      end
    end

    it 'removes /index from permalink of index pages' do
      with_temp_content_directory do
        index = create(:page, path: 'parent/child/index')
        assert_equal 'child', index.permalink
      end
    end
  end

  describe '#parent' do
    it 'finds the parent by inspecting the path' do
      with_temp_content_directory do
        parent = create(:page, path: 'parent')
        child = create(:page, path: 'parent/child')
        assert_equal parent, child.parent
      end
    end

    it 'returns nil for pages at top level' do
      with_temp_content_directory do
        assert_nil create(:page, path: 'top-level').parent
      end
    end

    it 'finds parents that are index pages' do
      with_temp_content_directory do
        home = create(:page, path: 'index')
        child = create(:page, path: 'parent')
        assert_equal home, child.parent
      end
    end

    it "returns grandparent if parent doesn't exist" do
      with_temp_content_directory do
        grandparent = create(:page, path: 'grandparent')
        child = create(:page, path: 'grandparent/parent/child')
        assert_equal grandparent, child.parent
      end
    end

    it 'recognises that home page can be returned as a grandparent' do
      with_temp_content_directory do
        grandparent = create(:page, path: 'index')
        child = create(:page, path: 'parent/child')
        assert_equal grandparent, child.parent
      end
    end

    it 'returns nil if page has no parent' do
      with_temp_content_directory do
        assert_nil create(:page, path: 'index').parent
      end
    end

    it 'finds parent of an index page' do
      with_temp_content_directory do
        parent = create(:page, path: 'parent')
        index = create(:page, path: 'parent/child/index')
        assert_equal parent, index.parent
      end
    end
  end

  describe '#priority' do
    it 'defaults to 0 for pages in category' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'categories' => 'the-category' })
        assert_equal 0, page.priority('the-category')
        assert_nil page.priority('another-category')
      end
    end

    it 'parses metadata to determine priority in each category' do
      with_temp_content_directory do
        page = create(:page, metadata: {
          'categories' => ' category-page:1, another-page , and-another :-1 '
        })
        assert_equal 1, page.priority('category-page')
        assert_equal 0, page.priority('another-page')
        assert_equal -1, page.priority('and-another')
      end
    end
  end

  describe '#pages' do
    it 'returns pages but not articles within this category' do
      with_temp_content_directory do
        category = create(:category)
        metadata = { 'categories' => category.path }
        page1 = create(:category, metadata: metadata)
        page2 = create(:category, metadata: metadata)
        create(:article, metadata: metadata)
        assert_equal [page1, page2], category.pages
      end
    end

    it 'sorts pages within a category by priority' do
      with_temp_content_directory do
        category = create(:category)
        create(:category, metadata: { 'categories' => category.path })
        page = create(:category, metadata: {
          'categories' => "#{category.path}:1"
        })
        assert_equal 0, category.pages.index(page)
      end
    end

    it 'orders pages within a category by heading if priority not set' do
      with_temp_content_directory do
        category = create(:category)
        metadata = { 'categories' => category.path }
        last = create(:category, heading: 'B', metadata: metadata)
        first = create(:category, heading: 'A', metadata: metadata)
        assert_equal [first, last], category.pages
      end
    end

    it 'filters out draft pages when running in production' do
      with_temp_content_directory do
        category = create(:category)
        create(:page, metadata: {
          'categories' => category.path,
          'flags' => 'draft'
        })
        fail 'should include draft pages' if category.pages.empty?
        Nesta::App.stub(:production?, true) do
          assert category.pages.empty?, 'should filter out draft pages'
        end
      end
    end
  end

  describe '#articles' do
    it "returns just the articles that are in this page's category" do
      with_temp_content_directory do
        category1 = create(:category)
        in_category1 = { 'categories' => category1.path }
        category2 = create(:category, metadata: in_category1)
        in_category2 = { 'categories' => category2.path }

        article1 = create(:article, metadata: in_category1)
        create(:article, metadata: in_category2)

        assert_equal [article1], category1.articles
      end
    end

    it 'returns articles in reverse chronological order' do
      with_temp_content_directory do
        category = create(:category)
        create(:article, metadata: {
          'date' => '30 December 2008',
          'categories' => category.path
        })
        latest = create(:article, metadata: {
          'date' => '31 December 2008',
          'categories' => category.path
        })
        assert_equal latest, category.articles.first
      end
    end
  end

  describe '#categories' do
    it "returns a page's categories" do
      with_temp_content_directory do
        category1 = create(:category, path: 'path/to/cat1')
        category2 = create(:category, path: 'path/to/cat2')
        article = create(:article, metadata: {
          'categories' => 'path/to/cat1, path/to/cat2'
        })
        assert_equal [category1, category2], article.categories
      end
    end

    it 'only returns categories that exist' do
      with_temp_content_directory do
        article = create(:article, metadata: { 'categories' => 'no-such-page' })
        assert_empty article.categories
      end
    end
  end

  describe '#to_html' do
    it 'produces no output if page has no content' do
      with_temp_content_directory do
        page = create(:page) do |path|
          file = File.open(path, 'w')
          file.close
        end
        assert_match /^\s*$/, Nesta::Page.find_by_path(page.path).to_html
      end
    end

    it 'converts page content to HTML' do
      with_temp_content_directory do
        assert_match %r{<h1>Hello</h1>}, create(:page, heading: 'Hello').to_html
      end
    end

    it "doesn't include leading metadata in HTML" do
      with_temp_content_directory do
        page = create(:page, metadata: { 'key' => 'value' })
        fail 'HTML contains metadata' if page.to_html =~ /(key|value)/
      end
    end
  end

  describe '#summary' do
    it 'returns value set in metadata wrapped in p tags' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'Summary' => 'Summary paragraph' })
        assert_equal "<p>Summary paragraph</p>\n", page.summary
      end
    end

    it 'treats double newline characters as paragraph breaks' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'Summary' => 'Line 1\n\nLine 2' })
        assert_includes page.summary, '<p>Line 1</p>'
        assert_includes page.summary, '<p>Line 2</p>'
      end
    end
  end

  describe '#body' do
    it "doesn't include page heading" do
      with_temp_content_directory do
        page = create(:page, heading: 'Heading')
        fail 'body contains heading' if page.body_markup =~ /#{page.heading}/
      end
    end
  end

  describe '#metadata' do
    it 'return value of any key set in metadata at top of page' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'Any key' => 'Any string' })
        assert_equal 'Any string', page.metadata('Any key')
      end
    end
  end

  describe '#layout' do
    it 'defaults to :layout' do
      with_temp_content_directory do
        assert_equal :layout, create(:page).layout
      end
    end

    it 'returns value set in metadata' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'Layout' => 'my_layout' })
        assert_equal :my_layout, page.layout
      end
    end
  end

  describe '#template' do
    it 'defaults to :page' do
      with_temp_content_directory do
        assert_equal :page, create(:page).template
      end
    end

    it 'returns value set in metadata' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'Template' => 'my_template' })
        assert_equal :my_template, page.template
      end
    end
  end

  describe '#link_text' do
    it 'raises error if neither heading nor link text set' do
      with_temp_content_directory do
        assert_raises Nesta::LinkTextNotSet do
          create(:page, heading: nil).link_text
        end
      end
    end

    it 'defaults to page heading' do
      with_temp_content_directory do
        page = create(:page)
        assert_equal page.heading, page.link_text
      end
    end

    it 'returns value set in metadata' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'link text' => 'Hello' })
        assert_equal 'Hello', page.link_text
      end
    end
  end

  describe '#read_more' do
    it 'has sensible default' do
      with_temp_content_directory do
        assert_equal 'Continue reading', create(:page).read_more
      end
    end

    it 'returns value set in metadata' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'Read more' => 'Click here' })
        assert_equal 'Click here', page.read_more
      end
    end
  end

  describe '#description' do
    it 'returns nil by default' do
      with_temp_content_directory { assert_nil create(:page).description }
    end

    it 'returns value set in metadata' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'description' => 'A page' })
        assert_equal 'A page', page.description
      end
    end
  end

  describe '#keywords' do
    it 'returns nil by default' do
      with_temp_content_directory { assert_nil create(:page).keywords }
    end

    it 'returns value set in metadata' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'keywords' => 'good, content' })
        assert_equal 'good, content', page.keywords
      end
    end
  end

  describe '#date' do
    it 'returns date article was published' do
      with_temp_content_directory do
        article = create(:article, metadata: { 'date' => 'November 18 2015' })
        assert_equal '18 November 2015', article.date.strftime('%d %B %Y')
      end
    end
  end

  describe '#flagged_as?' do
    it 'returns true if flags metadata contains the string' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'flags' => 'A flag, popular' })
        assert page.flagged_as?('popular'), 'should be flagged popular'
        assert page.flagged_as?('A flag'), 'should be flagged with "A flag"'
        fail 'not flagged as green' if page.flagged_as?('green')
      end
    end
  end

  describe '#draft?' do
    it 'returns true if page flagged as draft' do
      with_temp_content_directory do
        page = create(:page, metadata: { 'flags' => 'draft' })
        assert page.draft?
        fail 'not a draft' if create(:page).draft?
      end
    end
  end

  describe '#last_modified' do
    it 'reads last modified timestamp from disk' do
      with_temp_content_directory do
        page = create(:page)
        file_stat = Minitest::Mock.new
        file_stat.expect(:mtime, Time.parse('3 January 2009'))
        File.stub(:stat, file_stat) do
          assert_equal '03 Jan 2009', page.last_modified.strftime('%d %b %Y')
        end
        file_stat.verify
      end
    end
  end
end
