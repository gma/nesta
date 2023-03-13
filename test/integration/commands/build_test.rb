require 'test_helper'
require_relative '../../../lib/nesta/commands'

describe 'nesta build' do
  include ModelFactory
  include TestConfiguration

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
        command = Nesta::Commands::Build.new('output_dir')

        process = Minitest::Mock.new
        silencing_stdout { command.execute(process) }

        assert_exists_in_project File.join('output_dir', page.abspath + '.html')
      end
    end
  end
end
