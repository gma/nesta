require 'integration_test_helper'

describe 'XML sitemap' do
  include Nesta::IntegrationTest

  def visit_sitemap
    visit '/sitemap.xml'
  end

  def for_site_with_page(&block)
    with_temp_content_directory do
      model = create(:page)
      visit_sitemap
      yield(model)
    end
  end

  def for_site_with_article(&block)
    with_temp_content_directory do
      article = create(:article)
      visit_sitemap
      yield(article)
    end
  end

  it 'renders successfully' do
    for_site_with_page do
      assert_equal 200, page.status_code
    end
  end

  it 'has a urlset tag' do
    for_site_with_page do
      namespace = 'https://www.sitemaps.org/schemas/sitemap/0.9'
      assert_has_xpath "//urlset[@xmlns='#{namespace}']"
    end
  end

  it 'references the home page' do
    for_site_with_page do
      assert_has_xpath '//urlset/url/loc', text: 'http://www.example.com/'
    end
  end

  it 'configures home page to be checked frequently' do
    for_site_with_page do
      assert_has_xpath '//urlset/url/loc', text: "http://www.example.com/"
      assert_has_xpath '//urlset/url/changefreq', text: "daily"
      assert_has_xpath '//urlset/url/priority', text: "1.0"
    end
  end

  it "sets homepage lastmod from timestamp of most recently modified page" do
    for_site_with_article do |article|
      timestamp = article.last_modified
      assert_has_xpath '//urlset/url/loc', text: "http://www.example.com/"
      assert_has_xpath '//urlset/url/lastmod', text: timestamp.xmlschema
    end
  end

  def site_url(path)
    "http://www.example.com/#{path}"
  end

  it 'references category pages' do
    for_site_with_page do |model|
      assert_has_xpath '//urlset/url/loc', text: site_url(model.path)
    end
  end

  it 'references article pages' do
    for_site_with_article do |article|
      assert_has_xpath '//urlset/url/loc', text: site_url(article.path)
    end
  end

  it 'omits pages that have the skip-sitemap flag set' do
    with_temp_content_directory do
      create(:category)
      omitted = create(:page, metadata: { 'flags' => 'skip-sitemap' })
      visit_sitemap
      assert_has_no_xpath '//urlset/url/loc', text: site_url(omitted.path)
    end
  end
end
