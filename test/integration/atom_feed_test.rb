require 'integration_test_helper'

describe 'Atom feed' do
  include Nesta::IntegrationTest

  def visit_feed
    visit '/articles.xml'
  end

  describe 'site' do
    it 'renders successfully' do
      with_temp_content_directory do
        visit_feed
        assert_equal 200, page.status_code
      end
    end

    it "uses Atom's XML namespace" do
      with_temp_content_directory do
        visit_feed
        assert_has_xpath '//feed[@xmlns="https://www.w3.org/2005/Atom"]'
      end
    end

    it 'has an ID element' do
      with_temp_content_directory do
        visit_feed
        assert page.has_selector?('id:contains("tag:www.example.com,2009:/")')
      end
    end

    it 'has an alternate link element' do
      with_temp_content_directory do
        visit_feed
        assert_has_xpath(
          '//feed/link[@rel="alternate"][@href="http://www.example.com/"]')
      end
    end

    it 'has a self link element' do
      with_temp_content_directory do
        visit_feed
        assert_has_xpath(
          '//feed/link[@rel="self"][@href="http://www.example.com/articles.xml"]')
      end
    end

    it 'has title and subtitle' do
      site_config = {
        'title' => 'My blog',
        'subtitle' => 'about stuff',
      }
      stub_config(temp_content.merge(site_config)) do
        visit_feed
        assert_has_xpath '//feed/title[@type="text"]', text: 'My blog'
        assert_has_xpath '//feed/subtitle[@type="text"]', text: 'about stuff'
      end
    end

    it 'includes the author details' do
      author_config = temp_content.merge('author' => {
        'name' => 'Fred Bloggs',
        'uri' => 'http://fredbloggs.com',
        'email' => 'fred@fredbloggs.com'
      })
      stub_config(temp_content.merge(author_config)) do
        visit_feed
        assert_has_xpath '//feed/author/name', text: 'Fred Bloggs'
        assert_has_xpath '//feed/author/uri', text: 'http://fredbloggs.com'
        assert_has_xpath '//feed/author/email', text: 'fred@fredbloggs.com'
      end
    end
  end

  describe 'site with articles' do
    it 'only lists latest 10' do
      with_temp_content_directory do
        11.times { create(:article) }
        visit_feed
      end
      assert page.has_selector?('entry', count: 10), 'expected 10 articles'
    end
  end

  def with_category(options = {})
    with_temp_content_directory do
      model = create(:category, options)
      visit_feed
      yield(model)
    end
  end

  def with_article(options = {})
    with_temp_content_directory do
      article = create(:article, options)
      visit_feed
      yield(article)
    end
  end

  def with_article_in_category(options = {})
    with_temp_content_directory do
      category = create(:category, options)
      article_options = options.merge(metadata: {
        'categories' => category.path
      })
      article = create(:article, article_options)
      visit_feed
      yield(article, category)
    end
  end

  describe 'article' do
    it 'sets the title' do
      with_article do |article|
        assert_has_xpath '//entry/title', text: article.heading
      end
    end

    it 'links to the HTML version' do
      with_article do |article|
        url = "http://www.example.com/#{article.path}"
        assert_has_xpath(
          "//entry/link[@href='#{url}'][@rel='alternate'][@type='text/html']")
      end
    end

    it 'defines unique ID' do
      with_article do |article|
        assert_has_xpath(
          '//entry/id', text: "tag:www.example.com,2008-12-29:#{article.abspath}")
      end
    end

    it 'uses pre-defined ID if specified' do
      with_article(metadata: { 'atom id' => 'use-this-id' }) do
        assert_has_xpath '//entry/id', text: 'use-this-id'
      end
    end

    it 'specifies date published' do
      with_article do
        assert_has_xpath '//entry/published', text: '2008-12-29T00:00:00+00:00'
      end
    end

    it 'specifies article categories' do
      with_article_in_category do |article, category|
        assert_has_xpath "//category[@term='#{category.permalink}']"
      end
    end

    it 'has article content' do
      with_article do
        assert_has_xpath '//entry/content[@type="html"]', text: 'Content'
      end
    end

    it 'includes hostname in URLs' do
      with_article(content: '[a link](/foo)') do
        url = 'http://www.example.com/foo'
        assert_has_xpath '//entry/content', text: url
      end
    end

    it 'does not include article heading in content' do
      with_article do |article|
        assert page.has_no_selector?("summary:contains('#{article.heading}')")
      end
    end

    it 'does not include pages with no date in feed' do
      with_category(path: 'no-date') do
        assert page.has_no_selector?('entry id:contains("no-date")')
      end
    end
  end
end
