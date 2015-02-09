require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../../lib/nesta/commands', File.dirname(__FILE__))

describe "nesta:plugin:create" do
  include_context "temporary working directory"

  before(:each) do
    @name = 'my-feature'
    @gem_name = "nesta-plugin-#{@name}"
    @plugins_path = temp_path('plugins')
    @working_dir = Dir.pwd
    Dir.mkdir(@plugins_path)
    Dir.chdir(@plugins_path)
    @command = Nesta::Commands::Plugin::Create.new(@name)
    @command.stub(:run_process)
  end

  after(:each) do
    Dir.chdir(@working_dir)
    FileUtils.rm_r(@plugins_path)
  end

  it "should create a new gem prefixed with nesta-plugin" do
    @command.should_receive(:run_process).with('bundle', 'gem', @gem_name)
    begin
      @command.execute
    rescue Errno::ENOENT
      # This test is only concerned with running bundle gem; ENOENT
      # errors are raised because we didn't create a real gem.
    end
  end

  describe "after gem created" do
    def create_gem_file(*components)
      path = File.join(@plugins_path, @gem_name, *components)
      FileUtils.makedirs(File.dirname(path))
      File.open(path, 'w') { |f| yield f if block_given? }
      path
    end

    before(:each) do
      @required_file = create_gem_file('lib', "#{@gem_name}.rb")
      @init_file = create_gem_file('lib', @gem_name, 'init.rb')
      @gem_spec = create_gem_file("#{@gem_name}.gemspec") do |file|
        file.puts "  # specify any dependencies here; for example:"
        file.puts "end"
      end
    end

    after(:each) do
      FileUtils.rm(@required_file)
      FileUtils.rm(@init_file)
    end

    it "should create the ruby file loaded on require" do
      @command.execute
      File.read(@required_file).should include('Plugin.register(__FILE__)')
    end

    it "should create a default init.rb file" do
      @command.execute
      init = File.read(@init_file)
      boilerplate = <<-EOF
    module My::Feature
      module Helpers
      EOF
      init.should include(boilerplate)
      init.should include('helpers Nesta::Plugin::My::Feature::Helpers')
    end

    it "should specify plugin gem's dependencies" do
      @command.execute
      text = File.read(@gem_spec)
      text.should include('gem.add_dependency("nesta", ">= 0.9.11")')
      text.should include('gem.add_development_dependency("rake")')
    end
  end
end
