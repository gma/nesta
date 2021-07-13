require 'test_helper'
require_relative '../../../lib/nesta/commands'

describe 'nesta edit' do
  include TestConfiguration

  after do
    remove_temp_directory
  end

  it 'launches the editor' do
    ENV['EDITOR'] = 'vi'
    edited_file = 'path/to/page.md'
    process = Minitest::Mock.new
    process.expect(:run, true, [ENV['EDITOR'], /#{edited_file}$/])
    with_temp_content_directory do
      command = Nesta::Commands::Edit.new(edited_file)
      command.execute(process)
    end
  end
end
