require File.expand_path("spec_helper", File.dirname(__FILE__))
require File.expand_path("../lib/nesta/commands", File.dirname(__FILE__))

describe "nesta" do
  include FixtureHelper

  before(:each) do
    create_fixtures_directory
    @project_path = File.join(FixtureHelper::FIXTURE_DIR, 'mysite.com')
  end
  
  after(:each) do
    remove_fixtures
  end
  
  def project_path(path)
    File.join(@project_path, path)
  end

  def should_exist(file)
    File.exist?(project_path(file)).should be_true
  end

  describe "new" do
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

      it "should create the rackup file" do
        should_exist('config.ru')
      end

      it "should create the config.yml file" do
        should_exist('config/config.yml')
      end

      it "should add a Gemfile" do
        should_exist('Gemfile')
        gemfile_source.should match(/gem 'nesta', '#{Nesta::VERSION}'/)
      end
    end

    describe "--heroku" do
      before(:each) do
        Nesta::Commands::New.new(@project_path, 'heroku' => '').execute
      end

      it "should add heroku to Gemfile" do
        gemfile_source.should match(/gem 'heroku'/)
      end

      it "should add the heroku:config Rake task" do
        should_exist('Rakefile')
        rakefile_source.should match(/namespace :heroku/)
        rakefile_source.should match(/task :config/)
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

  describe "theme:install" do
    before(:each) do
      @repo_url = 'git://github.com/gma/nesta-theme-mine.git'
      @theme_dir = 'themes/mine'
      FileUtils.mkdir_p(File.join(@theme_dir, '.git'))
      @command = Nesta::Commands::Theme::Install.new(@repo_url)
      @command.stub!(:system)
    end

    after(:each) do
      FileUtils.rm_r(@theme_dir)
    end

    it "should clone the repository" do
      @command.should_receive(:system).with(
          'git', 'clone', @repo_url, @theme_dir)
      @command.execute
    end

    it "should remove the theme's .git directory" do
      @command.execute
      File.exist?(@theme_dir).should be_true
      File.exist?(File.join(@theme_dir, '.git')).should be_false
    end

    it "should enable the freshly installed theme" do
      @command.should_receive(:enable).with('mine')
      @command.execute
    end

    describe "when theme URL doesn't match recommendation" do
      before(:each) do
        @repo_url = 'git://foobar.com/path/to/mytheme.git'
        @other_theme_dir = 'themes/mytheme'
        FileUtils.mkdir_p(File.join(@other_theme_dir, '.git'))
        @command = Nesta::Commands::Theme::Install.new(@repo_url)
      end

      after(:each) do
        FileUtils.rm_r(@other_theme_dir)
      end

      it "should use the basename as theme dir" do
        @command.should_receive(:system).with(
            'git', 'clone', @repo_url, @other_theme_dir)
        @command.execute
      end
    end
  end

  describe "theme:enable" do
    before(:each) do
      config = File.join(FixtureHelper::FIXTURE_DIR, 'config.yml')
      Nesta::Config.stub!(:yaml_path).and_return(config)
      @name = 'mytheme'
      @command = Nesta::Commands::Theme::Enable.new(@name)
    end

    def create_config_yaml(text)
      File.open(Nesta::Config.yaml_path, 'w') { |f| f.puts(text) }
    end

    shared_examples_for "command that configures the theme" do
      it "should enable the theme" do
        @command.execute
        File.read(Nesta::Config.yaml_path).should match(/^theme: #{@name}/)
      end
    end

    describe "when theme config is commented out" do
      before(:each) do
        create_config_yaml('  # theme: blah')
      end

      it_should_behave_like "command that configures the theme"
    end

    describe "when another theme is configured" do
      before(:each) do
        create_config_yaml('theme: another')
      end

      it_should_behave_like "command that configures the theme"
    end

    describe "when no theme config exists" do
      before(:each) do
        create_config_yaml('# I have no theme config')
      end

      it_should_behave_like "command that configures the theme"
    end
  end

  describe "theme:create" do
    def should_exist(file)
      File.exist?(Nesta::Path.themes(@name, file)).should be_true
    end

    before(:each) do
      Nesta::App.stub!(:root).and_return(FixtureHelper::FIXTURE_DIR)
      @name = 'my-new-theme'
      Nesta::Commands::Theme::Create.new(@name).execute
    end

    it "should create the theme directory" do
      File.directory?(Nesta::Path.themes(@name)).should be_true
    end

    it "should create a dummy README file" do
      should_exist('README.md')
      text = File.read(Nesta::Path.themes(@name, 'README.md'))
      text.should match(/#{@name} is a theme/)
    end

    it "should create a default app.rb file" do
      should_exist('app.rb')
    end

    it "should create public and view directories" do
      should_exist("public/#{@name}")
      should_exist('views')
    end
  end
end
