require 'test_helper'
require_relative '../../../lib/nesta/commands'

describe 'nesta new' do
  include TemporaryFiles

  def gemfile_source
    File.read(project_path('Gemfile'))
  end

  def rakefile_source
    File.read(project_path('Rakefile'))
  end

  after do
    remove_temp_directory
  end

  def process_stub
    Object.new.tap do |stub|
      def stub.run(*args); end
    end
  end

  describe 'without options' do
    it 'creates the content directories' do
      Nesta::Commands::New.new(project_root).execute(process_stub)
      assert_exists_in_project 'content/attachments'
      assert_exists_in_project 'content/pages'
    end

    it 'creates the home page' do
      Nesta::Commands::New.new(project_root).execute(process_stub)
      assert_exists_in_project 'content/pages/index.haml'
    end

    it 'creates the rackup file' do
      Nesta::Commands::New.new(project_root).execute(process_stub)
      assert_exists_in_project 'config.ru'
    end

    it 'creates the config.yml file' do
      Nesta::Commands::New.new(project_root).execute(process_stub)
      assert_exists_in_project 'config/config.yml'
    end

    it 'creates a Gemfile' do
      Nesta::Commands::New.new(project_root).execute(process_stub)
      assert_exists_in_project 'Gemfile'
      assert_match /gem 'nesta'/, gemfile_source
    end
  end

  describe 'with --git option' do
    it 'creates a .gitignore file' do
      command = Nesta::Commands::New.new(project_root, 'git' => '')
      command.execute(process_stub)
      assert_match /\.bundle/, File.read(project_path('.gitignore'))
    end

    it 'creates a git repo' do
      command = Nesta::Commands::New.new(project_root, 'git' => '')
      process = Minitest::Mock.new
      process.expect(:run, true, ['git', 'init'])
      process.expect(:run, true, ['git', 'add', '.'])
      process.expect(:run, true, ['git', 'commit', '-m', 'Initial commit'])
      command.execute(process)
    end
  end

  describe 'with --vlad option' do
    it 'adds vlad to Gemfile' do
      Nesta::Commands::New.new(project_root, 'vlad' => '').execute(process_stub)
      assert_match /gem 'vlad', '2.1.0'/, gemfile_source
      assert_match /gem 'vlad-git', '2.2.0'/, gemfile_source
    end

    it 'configures the vlad rake tasks' do
      Nesta::Commands::New.new(project_root, 'vlad' => '').execute(process_stub)
      assert_exists_in_project 'Rakefile'
      assert_match /require 'vlad'/, rakefile_source
    end

    it 'creates deploy.rb' do
      Nesta::Commands::New.new(project_root, 'vlad' => '').execute(process_stub)
      assert_exists_in_project 'config/deploy.rb'
      deploy_source = File.read(project_path('config/deploy.rb'))
      assert_match /set :application, 'mysite.com'/, deploy_source
    end
  end
end
