require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../../lib/nesta/commands', File.dirname(__FILE__))

describe "nesta:demo:content" do
  include_context "temporary working directory"

  before(:each) do
    @config_path = project_path('config/config.yml')
    FileUtils.mkdir_p(File.dirname(@config_path))
    Nesta::Config.stub(:yaml_path).and_return(@config_path)
    create_config_yaml('content: path/to/content')
    Nesta::App.stub(:root).and_return(@project_path)
    @repo_url = 'git://github.com/gma/nesta-demo-content.git'
    @demo_path = project_path('content-demo')
    @command = Nesta::Commands::Demo::Content.new
    @command.stub(:run_process)
  end

  it "should clone the repository" do
    @command.should_receive(:run_process).with(
        'git', 'clone', @repo_url, @demo_path)
    @command.execute
  end

  it "should configure the content directory" do
    @command.execute
    File.read(@config_path).should match(/^content: content-demo/)
  end

  describe "when repository already exists" do
    before(:each) do
      FileUtils.mkdir_p(@demo_path)
    end

    it "should update the repository" do
      @command.should_receive(:run_process).with(
          'git', 'pull', 'origin', 'master')
      @command.execute
    end
  end

  describe "when site versioned with git" do
    before(:each) do
      @exclude_path = project_path('.git/info/exclude')
      FileUtils.mkdir_p(File.dirname(@exclude_path))
      File.open(@exclude_path, 'w') { |file| file.puts '# Excludes' }
    end

    it "should tell git to ignore content-demo" do
      @command.execute
      File.read(@exclude_path).should match(/content-demo/)
    end

    describe "and content-demo already ignored" do
      before(:each) do
        File.open(@exclude_path, 'w') { |file| file.puts 'content-demo' }
      end

      it "shouldn't tell git to ignore it twice" do
        @command.execute
        File.read(@exclude_path).scan('content-demo').size.should == 1
      end
    end
  end
end
