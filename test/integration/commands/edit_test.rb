require 'test_helper'
require_relative '../../../lib/nesta/commands'

describe 'nesta edit' do
  include TestConfiguration

  after do
    remove_temp_directory
  end

  it 'launches the editor' do
    ENV['EDITOR'] = 'touch'
    edited_file = 'path/to/page.md'
    with_temp_content_directory do
      FileUtils.mkdir_p(Nesta::Config.page_path(File.dirname(edited_file)))
      command = Nesta::Commands::Edit.new(edited_file)
      command.execute
      assert File.exist?(Nesta::Config.page_path(edited_file)), 'editor not run'
    end
  end
end
