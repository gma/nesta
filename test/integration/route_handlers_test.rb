require 'integration_test_helper'

describe 'Routing' do
  include Nesta::IntegrationTest

  it 'redirects requests with trailing slash' do
    with_temp_content_directory do
      model = create(:page)
      visit model.path + '/'
      assert_equal model.abspath, page.current_path
    end
  end

  describe 'not_found handler' do
    it 'returns HTTP code 404' do
      with_temp_content_directory do
        visit '/no-such-page'
        assert_equal 404, page.status_code
      end
    end
  end

  describe 'default route' do
    it 'provides access to helper methods in Haml pages' do
      with_temp_content_directory do
        model = create(:category,
                       ext: 'haml',
                       content: '%div= format_date(Date.new(2010, 11, 23))')
        visit model.path
        assert_has_css 'div', text: '23 November 2010'
      end
    end

    it 'should access helpers when rendering articles on a category page' do
      with_temp_content_directory do
        category = create(:page)
        create(
          :article,
          ext: 'haml',
          metadata: { 'categories' => category.path },
          content: "%h1 Heading\n\n%div= format_date(Date.new(2010, 11, 23))"
        )

        visit category.path

        assert_has_css 'div', text: '23 November 2010'
      end
    end
  end

  def create_attachment_in(directory)
    path = File.join(directory, 'test.txt')
    FileUtils.mkdir_p(directory)
    File.open(path, 'w') { |file| file.write("I'm a test attachment") }
  end

  describe 'attachments route' do
    it 'returns HTTP code 200' do
      with_temp_content_directory do
        create_attachment_in(Nesta::Config.attachment_path)
        visit '/attachments/test.txt'
        assert_equal 200, page.status_code
      end
    end

    it 'serves attachment to the client' do
      with_temp_content_directory do
        create_attachment_in(Nesta::Config.attachment_path)
        visit '/attachments/test.txt'
        assert_equal "I'm a test attachment", page.body
      end
    end

    it 'sets the appropriate MIME type' do
      with_temp_content_directory do
        create_attachment_in(Nesta::Config.attachment_path)
        visit '/attachments/test.txt'
        assert_match %r{^text/plain}, page.response_headers['Content-Type']
      end
    end

    it 'refuses to serve files outside the attachments directory' do
      # On earlier versions of Sinatra this test would have been handed
      # to the attachments handler. On the current version (1.4.5) it
      # appears as though the request is no longer matched by the
      # attachments route handler, which means we're not in danger of
      # serving serving files to attackers via `#send_file`.
      #
      # I've left the test in anyway, as without it we wouldn't become
      # aware of a security hole if there was a regression in Sinatra.
      #
      with_temp_content_directory do
        model = create(:page)
        visit "/attachments/../pages/#{File.basename(model.filename)}"
        assert_equal 404, page.status_code
      end
    end
  end
end
