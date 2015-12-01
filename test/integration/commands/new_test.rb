require 'test_helper'
require_relative '../../support/silence_commands_during_tests'
require_relative '../../../lib/nesta/commands'

Nesta::Commands::New.send(:include, SilenceCommandsDuringTests)

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

  describe 'without options' do
    it 'creates the content directories' do
      Nesta::Commands::New.new(project_root).execute
      assert_exists_in_project 'content/attachments'
      assert_exists_in_project 'content/pages'
    end

    it 'creates the home page' do
      Nesta::Commands::New.new(project_root).execute
      assert_exists_in_project 'content/pages/index.haml'
    end

    it 'creates the rackup file' do
      Nesta::Commands::New.new(project_root).execute
      assert_exists_in_project 'config.ru'
    end

    it 'creates the config.yml file' do
      Nesta::Commands::New.new(project_root).execute
      assert_exists_in_project 'config/config.yml'
    end

    it 'creates a Gemfile' do
      Nesta::Commands::New.new(project_root).execute
      assert_exists_in_project 'Gemfile'
      assert_match /gem 'nesta'/, gemfile_source
    end
  end

  describe 'with --git option' do
    it 'creates a .gitignore file' do
      command = Nesta::Commands::New.new(project_root, 'git' => '')
      command.stub(:run_process, nil) do
        command.execute
        assert_match /\.bundle/, File.read(project_path('.gitignore'))
      end
    end

    def disabling_git_hooks
      # I (@gma) have got a git repository template setup on my computer
      # containing git hooks that automatically run ctags in a
      # background process whenever I run `git commit`. The hooks are
      # copied into new repositories when I run `git init`.
      #
      # The generation of the ctags file (in a forked process) causes a
      # race condition; sometimes ctags will recreate a test's project
      # folder and git directory after the test's `after` block has
      # deleted it. If the project directory isn't removed after each
      # test, the New command will throw an error in the subsequent
      # test (complaining that the project directory already exists).
      #
      templates = temp_path('git_template')
      FileUtils.mkdir_p(templates)
      ENV['GIT_TEMPLATE_DIR'] = templates
      yield
      ENV.delete('GIT_TEMPLATE_DIR')
      FileUtils.rm_r(templates)
    end

    it 'creates a git repo' do
      disabling_git_hooks do
        command = Nesta::Commands::New.new(project_root, 'git' => '')
        command.execute
        assert_exists_in_project '.git/config'
      end
    end

    it 'commits the blank project' do
      disabling_git_hooks do
        command = Nesta::Commands::New.new(project_root, 'git' => '')
        command.execute
        Dir.chdir(project_root) do
          assert_match /Initial commit/, `git log --pretty=oneline | head -n 1`
        end
      end
    end
  end

  describe 'with --vlad option' do
    it 'adds vlad to Gemfile' do
      Nesta::Commands::New.new(project_root, 'vlad' => '').execute
      assert_match /gem 'vlad', '2.1.0'/, gemfile_source
      assert_match /gem 'vlad-git', '2.2.0'/, gemfile_source
    end

    it 'configures the vlad rake tasks' do
      Nesta::Commands::New.new(project_root, 'vlad' => '').execute
      assert_exists_in_project 'Rakefile'
      assert_match /require 'vlad'/, rakefile_source
    end

    it 'creates deploy.rb' do
      Nesta::Commands::New.new(project_root, 'vlad' => '').execute
      assert_exists_in_project 'config/deploy.rb'
      deploy_source = File.read(project_path('config/deploy.rb'))
      assert_match /set :application, 'mysite.com'/, deploy_source
    end
  end
end
