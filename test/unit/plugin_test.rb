require 'test_helper'

describe Nesta::Plugin do
  def remove_plugin_from_list_of_required_files
    $LOADED_FEATURES.delete_if do |path|
      path =~ /nesta-plugin-test/
    end
  end

  def remove_plugin_constants
    Nesta::Plugin::Test.send(:remove_const, :VERSION)
  rescue NameError
  end

  before do
    @plugin_lib_path = File.expand_path(
      File.join(%w(.. fixtures nesta-plugin-test lib)), File.dirname(__FILE__)
    )
    $LOAD_PATH.unshift(@plugin_lib_path)
    Nesta::Plugin.loaded.clear
  end

  after do
    $LOAD_PATH.shift if $LOAD_PATH[0] == @plugin_lib_path
    remove_plugin_from_list_of_required_files
    remove_plugin_constants
  end

  it 'must be required in order to load' do
    assert Nesta::Plugin.loaded.empty?, 'should be empty'
  end

  it 'records loaded plugins' do
    require 'nesta-plugin-test'
    assert_equal ['nesta-plugin-test'], Nesta::Plugin.loaded
  end

  it 'loads the plugin module' do
    require 'nesta-plugin-test'
    Nesta::Plugin::Test::VERSION
  end

  it 'initializes the plugin' do
    require 'nesta-plugin-test'
    Nesta::Plugin.initialize_plugins
    assert Nesta::Page.respond_to?(:method_added_by_plugin), 'not initialized'
  end
end
