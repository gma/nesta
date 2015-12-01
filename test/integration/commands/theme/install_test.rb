require 'test_helper'
require_relative '../../../support/silence_commands_during_tests'
require_relative '../../../../lib/nesta/commands'

Nesta::Commands::Theme::Install.send(:include, SilenceCommandsDuringTests)

describe 'nesta theme:install' do
  include TemporaryFiles

  def theme_name
    'test'
  end

  def repo_url
    "../../fixtures/nesta-theme-#{theme_name}.git"
  end

  def theme_dir
    project_path("themes/#{theme_name}")
  end

  before do
    FileUtils.mkdir_p(project_root)
  end

  after do
    remove_temp_directory
  end

  it 'clones the repository' do
    in_temporary_project do
      Nesta::Commands::Theme::Install.new(repo_url).execute
      assert File.directory?(theme_dir), 'theme not cloned'
    end
  end

  it "removes the theme's .git directory" do
    in_temporary_project do
      Nesta::Commands::Theme::Install.new(repo_url).execute
      refute File.exist?("#{theme_dir}/.git"), '.git folder found'
    end
  end

  it 'enables the freshly installed theme' do
    in_temporary_project do
      Nesta::Commands::Theme::Install.new(repo_url).execute
      assert_match /theme: #{theme_name}/, File.read('config/config.yml')
    end
  end

  it 'determines name of theme from name of repository' do
    url = 'git://foobar.com/path/to/nesta-theme-the-name.git'
    command = Nesta::Commands::Theme::Install.new(url)
    assert_equal 'the-name', command.theme_name
  end

  it "falls back to name of repo when theme name doesn't match correct format" do
    url = 'git://foobar.com/path/to/mytheme.git'
    command = Nesta::Commands::Theme::Install.new(url)
    assert_equal 'mytheme', command.theme_name
  end
end
