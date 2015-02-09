require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../../lib/nesta/commands', File.dirname(__FILE__))

describe "nesta:theme:enable" do
  include_context "temporary working directory"

  before(:each) do
    config = temp_path('config.yml')
    Nesta::Config.stub(:yaml_path).and_return(config)
    @name = 'mytheme'
    @command = Nesta::Commands::Theme::Enable.new(@name)
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
