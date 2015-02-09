require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../lib/nesta/commands', File.dirname(__FILE__))

describe "nesta:new" do
  include_context "temporary working directory"

  def gemfile_source
    File.read(project_path('Gemfile'))
  end

  def rakefile_source
    File.read(project_path('Rakefile'))
  end

  describe "without options" do
    before(:each) do
      Nesta::Commands::New.new(@project_path).execute
    end

    it "should create the content directories" do
      should_exist('content/attachments')
      should_exist('content/pages')
    end

    it "should create the home page" do
      should_exist('content/pages/index.haml')
    end

    it "should create the rackup file" do
      should_exist('config.ru')
    end

    it "should create the config.yml file" do
      should_exist('config/config.yml')
    end

    it "should add a Gemfile" do
      should_exist('Gemfile')
      gemfile_source.should match(/gem 'nesta'/)
    end
  end

  describe "--git" do
    before(:each) do
      @command = Nesta::Commands::New.new(@project_path, 'git' => '')
      @command.stub(:run_process)
    end

    it "should create a .gitignore file" do
      @command.execute
      File.read(project_path('.gitignore')).should match(/\.bundle/)
    end

    it "should create a git repo" do
      @command.should_receive(:run_process).with('git', 'init')
      @command.execute
    end

    it "should commit the blank project" do
      @command.should_receive(:run_process).with('git', 'add', '.')
      @command.should_receive(:run_process).with(
          'git', 'commit', '-m', 'Initial commit')
      @command.execute
    end
  end

  describe "--vlad" do
    before(:each) do
      Nesta::Commands::New.new(@project_path, 'vlad' => '').execute
    end

    it "should add vlad to Gemfile" do
      gemfile_source.should match(/gem 'vlad', '2.1.0'/)
      gemfile_source.should match(/gem 'vlad-git', '2.2.0'/)
    end

    it "should configure the vlad rake tasks" do
      should_exist('Rakefile')
      rakefile_source.should match(/require 'vlad'/)
    end

    it "should create deploy.rb" do
      should_exist('config/deploy.rb')
      deploy_source = File.read(project_path('config/deploy.rb'))
      deploy_source.should match(/set :application, 'mysite.com'/)
    end
  end
end
