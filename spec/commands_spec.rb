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
  
  def command(name, *args)
    Nesta::Commands.const_get(name.to_s.capitalize.to_sym).new(*args)
  end

  def project_path(path)
    File.join(@project_path, path)
  end

  def should_exist(file)
    File.exist?(project_path(file)).should be_true
  end

  describe "new" do
    describe "without options" do
      before(:each) do
        command(:new, @project_path).create
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
        gemfile_source = File.read(project_path('Gemfile'))
        gemfile_source.should match(/gem 'nesta', '#{Nesta::VERSION}'/)
      end
    end

    describe "--heroku" do
      before(:each) do
        command(:new, @project_path, 'heroku' => '').create
      end

      it "should add the heroku:config Rake task" do
        should_exist('Rakefile')
        rake_source = File.read(project_path('Rakefile'))
        rake_source.should match(/namespace :heroku/)
        rake_source.should match(/task :config/)
      end
    end
  end

  describe "theme:install" do
    before(:each) do
      @repo_url = 'git://github.com/gma/nesta-theme-mine.git'
      @theme_dir = 'themes/mine'
      FileUtils.mkdir_p(File.join(@theme_dir, '.git'))
      @command = command(:theme)
      @command.stub!(:system)
    end

    after(:each) do
      FileUtils.rm_r(@theme_dir)
    end

    it "should clone the repository" do
      @command.should_receive(:system).with(
          'git', 'clone', @repo_url, @theme_dir)
      @command.install(@repo_url)
    end

    it "should remove the theme's .git directory" do
      @command.install(@repo_url)
      File.exist?(@theme_dir).should be_true
      File.exist?(File.join(@theme_dir, '.git')).should be_false
    end

    it "should enable the freshly installed theme" do
      @command.should_receive(:enable).with('mine')
      @command.install(@repo_url)
    end

    describe "when theme URL doesn't match recommendation" do
      before(:each) do
        @repo_url = 'git://foobar.com/path/to/mytheme.git'
        @other_theme_dir = 'themes/mytheme'
        FileUtils.mkdir_p(File.join(@other_theme_dir, '.git'))
        @command = command(:theme)
      end

      after(:each) do
        FileUtils.rm_r(@other_theme_dir)
      end

      it "should use the basename as theme dir" do
        @command.should_receive(:system).with(
            'git', 'clone', @repo_url, @other_theme_dir)
        @command.install(@repo_url)
      end
    end
  end

  describe "theme:enable" do
    before(:each) do
      config = File.join(FixtureHelper::FIXTURE_DIR, 'config.yml')
      Nesta::Config.stub!(:yaml_path).and_return(config)
      @command = command(:theme)
    end

    def create_config_yaml(text)
      File.open(Nesta::Config.yaml_path, 'w') { |f| f.puts(text) }
    end

    shared_examples_for "command that configures the theme" do
      it "should enable the theme" do
        @command.enable('mytheme')
        File.read(Nesta::Config.yaml_path).should match(/^theme: mytheme/)
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

  # describe "theme:create" do
  #   it "should create the theme directory"
  #   it "should create a dummy README file"
  #   it "should create a default app.rb file"
  #   it "should create public and view directories"

  #   describe "when theme already exists" do
  #     it "should refuse to do anything"
  #   end
  # end
end
