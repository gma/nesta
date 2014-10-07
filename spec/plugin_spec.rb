require 'spec_helper'

describe Nesta::Plugin do
  describe "#register" do
    before(:each) do
      Nesta::Plugin.loaded.clear
    end

    context "with an absolute file path" do
      it "should load plugin" do
        Nesta::Plugin.register('/path/to/nesta-plugin-test.rb')
        Nesta::Plugin.loaded.size.should == 1
        Nesta::Plugin.loaded.last.should == 'nesta-plugin-test'
      end
    end

    context "with a namespace path" do
      it "should load plugin" do
        namespace_path = 'nesta/plugin/test'
        Nesta::Plugin.register(namespace_path)
        Nesta::Plugin.loaded.size.should == 1
        Nesta::Plugin.loaded.last.should == namespace_path
      end
    end

    context "an invalid plugin name" do
      it "should raise an error" do
        expect { Nesta::Plugin.register('test') }.to raise_error(RuntimeError)
      end
    end
  end
end

describe "Plugin gem loading" do
  include ConfigSpecHelper

  def remove_plugin_from_list_of_required_files
    $".delete_if { |path| path =~ /nesta-plugin-test/ }  # feel free to vomit
  end

  def remove_plugin_constants
    Nesta::Plugin::Test
  rescue NameError
  else
    Nesta::Plugin::Test.send(:remove_const, :VERSION)
  end

  before(:each) do
    stub_configuration
    @plugin_lib_path = File.expand_path(
        File.join(%w(fixtures nesta-plugin-test lib)), File.dirname(__FILE__))
    $LOAD_PATH.unshift(@plugin_lib_path)
    Nesta::Plugin.loaded.clear
  end

  after(:each) do
    $LOAD_PATH.shift if $LOAD_PATH[0] == @plugin_lib_path
    remove_plugin_from_list_of_required_files
    remove_plugin_constants
  end

  it "should not occur prior to gem is required" do
    Nesta::Plugin.loaded.should be_empty
  end

  it "should record loaded plugins" do
    require 'nesta-plugin-test'
    Nesta::Plugin.loaded.size.should == 1
    Nesta::Plugin.loaded.last.should == 'nesta-plugin-test'
  end

  it "should have loaded the plugin's module" do
    require 'nesta-plugin-test'
    Nesta::Plugin::Test::VERSION
  end

  it "should initialize the plugin" do
    require 'nesta-plugin-test'
    Nesta::Plugin.initialize_plugins
    Nesta::Page.should respond_to(:method_added_by_plugin)
  end
end
