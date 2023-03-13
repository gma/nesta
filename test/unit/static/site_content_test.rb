require 'test_helper'

require_relative '../../../lib/nesta/static/site_content'

describe 'SiteContent' do
  include ModelFactory
  include TestConfiguration

  after do
    remove_temp_directory
  end

  it 'converts Markdown to HTML' do
    build_dir = 'dist'

    in_temporary_project do
      with_temp_content_directory do
        page = create(:page)

        Nesta::Static::SiteContent.new(build_dir).render_pages

        html_file = File.join(build_dir, page.abspath + '.html')
        markup = open(html_file).read

        assert markup.include?("<title>#{page.title}</title>")
      end
    end
  end

  it 'renders a 404 not found page' do
    build_dir = 'dist'

    in_temporary_project do
      with_temp_content_directory do
        Nesta::Static::SiteContent.new(build_dir).render_not_found

        html_file = File.join(build_dir, '404.html')
        markup = open(html_file).read

        assert markup.include?("<h1>Page not found</h1>")
      end
    end
  end
end
