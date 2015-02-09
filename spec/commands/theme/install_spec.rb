require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../../lib/nesta/commands', File.dirname(__FILE__))

describe "nesta:theme:install" do
  include_context "temporary working directory"

  before(:each) do
    @repo_url = 'git://github.com/gma/nesta-theme-mine.git'
    @theme_dir = 'themes/mine'
    FileUtils.mkdir_p(File.join(@theme_dir, '.git'))
    @command = Nesta::Commands::Theme::Install.new(@repo_url)
    @command.stub(:enable)
    @command.stub(:run_process)
  end

  after(:each) do
    FileUtils.rm_r(@theme_dir)
  end

  it "should clone the repository" do
    @command.should_receive(:run_process).with(
      'git', 'clone', @repo_url, @theme_dir)
    @command.execute
  end

  it "should remove the theme's .git directory" do
    @command.execute
    File.exist?(@theme_dir).should be_true
    File.exist?(File.join(@theme_dir, '.git')).should be_false
  end

  it "should enable the freshly installed theme" do
    @command.should_receive(:enable)
    @command.execute
  end

  describe "when theme URL doesn't match recommended pattern" do
    before(:each) do
      @repo_url = 'git://foobar.com/path/to/mytheme.git'
      @other_theme_dir = 'themes/mytheme'
      FileUtils.mkdir_p(File.join(@other_theme_dir, '.git'))
      @command = Nesta::Commands::Theme::Install.new(@repo_url)
      @command.stub(:enable)
    end

    after(:each) do
      FileUtils.rm_r(@other_theme_dir)
    end

    it "should use the basename as theme dir" do
      @command.should_receive(:run_process).with(
        'git', 'clone', @repo_url, @other_theme_dir)
      @command.execute
    end
  end
end
