require 'integration_test_helper'

describe 'Default theme' do
  include Nesta::IntegrationTest

  def in_categories(*categories)
    { 'categories' => categories.map(&:path).join(', ') }
  end

  it 'includes description meta tag' do
    with_temp_content_directory do
      model = create(:page, metadata: { 'Description' => 'A good page' })
      visit model.path
      xpath = "//meta[@name='description'][@content='A good page']"
      assert_has_xpath xpath, visible: false
    end
  end

  it 'includes keywords meta tag' do
    with_temp_content_directory do
      model = create(:page, metadata: { 'Keywords' => 'good, content' })
      visit model.path
      xpath = "//meta[@name='keywords'][@content='good, content']"
      assert_has_xpath xpath, visible: false
    end
  end

  it "doesn't include Google Analytics JavaScript snippet by default" do
    with_temp_content_directory do
      visit '/'
      assert_has_no_css 'script', text: 'google-analytics.com'
    end
  end

  it 'includes Google Analytics JavaScript when configured' do
    analytics_code = { 'google_analytics_code' => 'UA-1234' }
    stub_config(temp_content.merge('test' => analytics_code)) do
      visit '/'
      assert_nil all('script').find { |s| s[:src].match /analytics\.js/ }
    end
  end

  it 'displays site title' do
    site_config = {
      'title' => 'My blog',
      'subtitle' => 'about stuff',
    }
    stub_config(temp_content.merge(site_config)) do
      visit '/'
      assert_has_css 'h1', text: 'My blog'
      assert_has_css 'h2', text: 'about stuff'
    end
  end

  describe 'menus' do
    def create_pages_in_menu
      pages
    end

    it "doesn't include menu markup if menu not configured" do
      with_temp_content_directory do
        visit '/'
        assert_has_no_css 'ul.menu'
      end
    end

    it 'only displays first two levels of menu items' do
      with_temp_content_directory do
        level1, level2, level3 = (0..2).map { create(:page) }
        text = "%s\n  %s\n    %s\n" % [level1, level2, level3].map(&:abspath)
        create_menu(text)
        visit '/'
        assert_has_css "ul.menu li a:contains('#{level1.link_text}')"
        assert_has_css "ul.menu li ul li a:contains('#{level2.link_text}')"
        assert_has_no_css "ul.menu a:contains('#{level3.link_text}')"
      end
    end
  end

  it 'only displays read more link for summarised pages' do
    with_temp_content_directory do
      category = create(:category)
      metadata = in_categories(category)
      summarised = create(:page, metadata: metadata.merge('summary' => 'Summary'))
      not_summarised = create(:page, metadata: metadata)
      visit category.path
      assert_has_css 'li:nth-child(1) p', text: summarised.read_more
      assert_has_no_css 'li:nth-child(2) p', text: not_summarised.read_more
    end
  end

  it 'displays page summaries or full content of unsummarised pages' do
    with_temp_content_directory do
      category = create(:category)
      metadata = in_categories(category)
      summarised = create(:page,
                          content: 'Summarised content',
                          metadata: metadata.merge(summary: 'Summary'))
      not_summarised = create(:page,
                              content: 'Unsummarised content',
                              metadata: metadata)
      visit category.path

      # Page with a summary
      assert_has_css 'li:nth-child(1) p', text: 'Summary'
      assert_has_no_css 'li:nth-child(1) p', text: 'content'

      # Page without a summary
      assert_has_css 'li:nth-child(2) p', text: 'Unsummarised content'
      assert_has_no_css 'li:nth-child(2) p', text: 'Summary'
    end
  end

  it 'displays contents of page' do
    with_temp_content_directory do
      model = create(:page, content: 'Body of page')
      visit model.path
      assert_has_css 'p', text: 'Body of page'
    end
  end

  describe 'category' do
    it 'displays its "articles heading" above the articles' do
      with_temp_content_directory do
        category = create(:category, metadata: {
          'articles heading' => 'Articles on this topic'
        })
        create(:article, metadata: in_categories(category))
        visit category.path
        assert_has_css 'h1', text: 'Articles on this topic'
      end
    end

    it 'links to articles in category using article title' do
      with_temp_content_directory do
        category = create(:category)
        article = create(:article, metadata: in_categories(category))
        visit category.path
        link_text, href = article.link_text, article.abspath
        assert_has_css "ol h1 a[href$='#{href}']", text: link_text
      end
    end
  end

  describe 'article' do
    it 'displays the date' do
      with_temp_content_directory do
        article = create(:article)
        visit article.path
        assert_has_css 'time', article.date
      end
    end

    it 'links to parent page in breadcrumb' do
      with_temp_content_directory do
        parent = create(:category)
        article = create(:article, path: "#{parent.path}/child")
        visit article.path
        href, link_text = parent.abspath, parent.link_text
        assert_has_css "nav.breadcrumb a[href='#{href}']", text: link_text
      end
    end

    it 'links to its categories at end of article' do
      with_temp_content_directory do
        categories = [create(:category), create(:category)]
        article = create(:article, metadata: in_categories(*categories))
        visit article.path
        categories.each do |category|
          href, link_text = category.abspath, category.link_text
          assert_has_css "p.meta a[href$='#{href}']", text: link_text
        end
      end
    end

    it 'displays comments from Disqus' do
      stub_config(temp_content.merge('disqus_short_name' => 'mysite')) do
        article = create(:article)
        visit article.path
        assert_has_css '#disqus_thread'
        assert_has_css 'script[src*="mysite.disqus.com"]', visible: false
      end
    end

    it "doesn't use Disqus if it's not configured" do
      with_temp_content_directory do
        visit create(:article).path
        assert_has_no_css '#disqus_thread'
      end
    end
  end
end
