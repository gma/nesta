require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../../lib/nesta/commands', File.dirname(__FILE__))

describe "nesta:plugin:create" do
  include_context "temporary working directory"

  def path_in_gem(path)
    File.join(@gem_name, path)
  end

  def should_exist(path)
    File.exist?(path_in_gem(path)).should be_true
  end
  
  def should_contain(path, pattern)
    contents = File.read(path_in_gem(path))
    contents.should match(pattern)
  end

  before(:each) do
    @name = 'my-feature'
    @gem_name = "nesta-plugin-#{@name}"
    @plugins_path = temp_path('plugins')
    @working_dir = Dir.pwd
    Dir.mkdir(@plugins_path)
    Dir.chdir(@plugins_path)
    Nesta::Commands::Plugin::Create.new(@name).execute
  end

  after(:each) do
    Dir.chdir(@working_dir)
    FileUtils.rm_r(@plugins_path)
  end

  it "creates the gem's directory" do
    File.directory?(@gem_name).should be_true
  end

  it "creates .gitignore" do
    should_exist('.gitignore')
  end

  it "creates the gemspec" do
    path = "#{@gem_name}.gemspec"
    should_exist(path)
    should_contain(path, %r{require "#{@gem_name}/version"})
    should_contain(path, %r{Nesta::Plugin::My::Feature::VERSION})
  end

  it "creates a Gemfile" do
    should_exist('Gemfile')
  end

  it "creates Rakefile that helps with packaging the gem"

  it "creates default folder for Ruby files" do
    code_directory = File.join(@gem_name, 'lib', @gem_name)
    File.directory?(code_directory).should be_true
  end

  it "creates file required when gem loaded" do
    path = "#{File.join('lib', @gem_name)}.rb"
    should_exist(path)
    should_contain(path, %r{require "#{@gem_name}/version"})
  end
end
