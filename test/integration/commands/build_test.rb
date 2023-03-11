require 'test_helper'
require_relative '../../../lib/nesta/commands'

describe 'nesta build' do
  include ModelFactory
  include TestConfiguration

  after do
    remove_temp_directory
  end

  it 'determines HTML filename from build dir and page filename' do
    build_dir = Nesta::Commands::Build::DEFAULT_DESTINATION
    command = Nesta::Commands::Build.new

    with_temp_content_directory do
      page = create(:page)

      html_filename = command.html_filename(page)

      assert_equal File.join(build_dir, "page-1.html"), html_filename
    end
  end

  it 'creates index.html in directory if page shares path with directory' do
    build_dir = Nesta::Commands::Build::DEFAULT_DESTINATION
    command = Nesta::Commands::Build.new

    with_temp_content_directory do
      page = create(:page)
      ext = File.extname(page.filename)
      directory_path = page.filename.sub(/#{ext}$/, '')
      FileUtils.mkdir(directory_path)

      html_filename = command.html_filename(page)

      assert_equal File.join(build_dir, "page-1", "index.html"), html_filename
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
        command = Nesta::Commands::Build.new

        process = Minitest::Mock.new
        silencing_stdout { command.execute(process) }

        assert_exists_in_project command.html_filename(page)
      end
    end
  end
end
