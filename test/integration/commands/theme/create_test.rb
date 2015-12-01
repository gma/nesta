require 'test_helper'
require_relative '../../../../lib/nesta/commands'

describe 'nesta theme:create' do
  include TemporaryFiles

  def theme_path(path = '')
    File.join('themes', 'theme-name', path)
  end

  before do
    FileUtils.mkdir_p(project_root)
  end

  after do
    remove_temp_directory
  end

  it 'creates default files in the theme directory' do
    Dir.chdir(project_root) do
      Nesta::Commands::Theme::Create.new('theme-name').execute
    end
    assert_exists_in_project theme_path('README.md')
    assert_exists_in_project theme_path('app.rb')
  end

  it 'copies default view templates into views directory' do
    Dir.chdir(project_root) do
      Nesta::Commands::Theme::Create.new('theme-name').execute
    end
    %w(layout.haml page.haml master.sass).each do |template|
      assert_exists_in_project theme_path("views/#{template}")
    end
  end
end
