require 'test_helper'

require_relative '../../../lib/nesta/static/html_file'

describe 'HtmlFile' do
  include ModelFactory
  include TestConfiguration

  after do
    remove_temp_directory
  end

  it 'determines HTML filename from build dir and page filename' do
    build_dir = 'dist'

    with_temp_content_directory do
      page = create(:page)

      html_file = Nesta::Static::HtmlFile.new(build_dir, page)

      expected = File.join(build_dir, 'page-1.html')
      assert_equal expected, html_file.filename
    end
  end

  it 'creates index.html in directory if page shares path with directory' do
    build_dir = 'dist'

    with_temp_content_directory do
      page = create(:page)
      ext = File.extname(page.filename)
      directory_path = page.filename.sub(/#{ext}$/, '')
      FileUtils.mkdir(directory_path)

      html_file = Nesta::Static::HtmlFile.new(build_dir, page)

      expected = File.join(build_dir, 'page-1', 'index.html')
      assert_equal expected, html_file.filename
    end
  end
end
