require 'test_helper'
require_relative '../../../lib/nesta/commands'

describe 'nesta build' do
  include ModelFactory
  include TestConfiguration

  after do
    remove_temp_directory
  end

  describe 'HtmlFile' do
    it 'determines HTML filename from build dir and page filename' do
      build_dir = Nesta::Commands::Build::DEFAULT_DESTINATION

      with_temp_content_directory do
        page = create(:page)

        html_file = Nesta::Commands::Build::HtmlFile.new(build_dir, page)

        assert_equal File.join(build_dir, "page-1.html"), html_file.filename
      end
    end

    it 'creates index.html in directory if page shares path with directory' do
      build_dir = Nesta::Commands::Build::DEFAULT_DESTINATION

      with_temp_content_directory do
        page = create(:page)
        ext = File.extname(page.filename)
        directory_path = page.filename.sub(/#{ext}$/, '')
        FileUtils.mkdir(directory_path)

        html_file = Nesta::Commands::Build::HtmlFile.new(build_dir, page)

        expected = File.join(build_dir, "page-1", "index.html")
        assert_equal expected, html_file.filename
      end
    end
  end

  def silencing_stdout(&block)
    stdout, $stdout = $stdout, StringIO.new
    yield
  ensure
    $stdout.close
    $stdout = stdout
  end

  it 'builds HTML file from Markdown file' do
    in_temporary_project do
      with_temp_content_directory do
        page = create(:page)
        command = Nesta::Commands::Build.new("output_dir")
        html_file = Nesta::Commands::Build::HtmlFile.new("output_dir", page)

        process = Minitest::Mock.new
        silencing_stdout { command.execute(process) }

        assert_exists_in_project html_file.filename
      end
    end
  end
end
