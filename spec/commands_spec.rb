require File.expand_path("spec_helper", File.dirname(__FILE__))
require File.expand_path("../lib/nesta/commands", File.dirname(__FILE__))

describe "nesta" do
  include FixtureHelper

  before(:each) do
    create_fixtures_directory
    @project_path = File.join(FixtureHelper::FIXTURE_DIR, "mysite.com")
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
        command(:new, @project_path)
      end

      it "should create the rackup file" do
        should_exist('config.ru')
      end

      it "should create the content directories" do
        should_exist('content/attachments')
        should_exist('content/pages')
      end

      it "should create the config.yml file" do
        should_exist('config/config.yml')
      end
    end

    describe "--heroku" do
      before(:each) do
        command(:new, @project_path, 'heroku' => '')
      end

      it "should add a Gemfile" do
        should_exist('Gemfile')
        gemfile_source = File.read(project_path('Gemfile'))
        gemfile_source.should match(/gem 'nesta', '#{Nesta::VERSION}'/)
      end

      it "should add the heroku:config Rake task" do
        should_exist('Rakefile')
        rake_source = File.read(project_path('Rakefile'))
        rake_source.should match(/namespace :heroku/)
        rake_source.should match(/task :config/)
      end
    end
  end
end
