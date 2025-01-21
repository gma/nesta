require 'test_helper'
require_relative '../../../lib/nesta/commands'

describe 'nesta build' do
  include ModelFactory
  include TestConfiguration

  def silencing_stdout(&block)
    stdout, $stdout = $stdout, StringIO.new
    block.call
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

  it 'reads domain name from config file' do
    domain = 'mysite.com'

    in_temporary_project do
      stub_config('build' => { 'domain' => domain }) do
        command = Nesta::Commands::Build.new('output_dir')

        assert_equal domain, command.domain
      end
    end
  end

  it 'overrides domain name if set on command line' do
    domain = 'mysite.com'

    in_temporary_project do
      stub_config('build' => { 'domain' => 'ignored.com' }) do
        command = Nesta::Commands::Build.new('output_dir', 'domain' => domain)

        assert_equal domain, command.domain
      end
    end
  end
end
