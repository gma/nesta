require 'test_helper'
require_relative '../../../../lib/nesta/commands'

describe 'nesta plugin:create' do
  include TemporaryFiles

  def working_directory
    temp_path('plugins')
  end

  before do
    FileUtils.mkdir_p(working_directory)
  end

  after do
    remove_temp_directory
  end

  def plugin_name
    'my-feature'
  end

  def gem_name
    "nesta-plugin-#{plugin_name}"
  end

  def process_stub
    Object.new.tap do |stub|
      def stub.run(*args); end
    end
  end

  def create_plugin(&block)
    Dir.chdir(working_directory) do
      command = Nesta::Commands::Plugin::Create.new(plugin_name)
      command.execute(process_stub)
    end
  end

  def assert_exists_in_plugin(path)
    full_path = File.join(gem_name, path)
    assert File.exist?(full_path), "#{path} not found in plugin"
  end

  def assert_file_contains(path, pattern)
    assert_match pattern, File.read(File.join(gem_name, path))
  end

  it "creates the gem's directory" do
    create_plugin { assert File.directory?(gem_name), 'gem directory not found' }
  end

  it 'creates README.md file' do
    create_plugin { assert_exists_in_plugin('README.md') }
  end

  it 'includes installation instructions in README.md' do
    create_plugin do
      assert_file_contains('README.md', /echo 'gem "#{gem_name}"' >> Gemfile/)
    end
  end

  it 'creates .gitignore file' do
    create_plugin { assert_exists_in_plugin('.gitignore') }
  end

  it 'creates the gemspec' do
    create_plugin do
      gemspec = "#{gem_name}.gemspec"
      assert_exists_in_plugin(gemspec)
      assert_file_contains(gemspec, %r{require "#{gem_name}/version"})
      assert_file_contains(gemspec, %r{Nesta::Plugin::My::Feature::VERSION})
    end
  end

  it 'creates a Gemfile' do
    create_plugin { assert_exists_in_plugin('Gemfile') }
  end

  it 'creates Rakefile for packaging the gem' do
    create_plugin { assert_exists_in_plugin('Rakefile') }
  end

  it "creates default folder for Ruby files" do
    create_plugin do
      code_directory = File.join(gem_name, 'lib', gem_name)
      assert File.directory?(code_directory), 'directory for code not found'
    end
  end

  it 'creates file required when gem loaded' do
    create_plugin do
      path = "#{File.join('lib', gem_name)}.rb"
      assert_exists_in_plugin(path)
      assert_file_contains(path, %r{require "#{gem_name}/version"})
    end
  end

  it 'creates version.rb' do
    create_plugin do
      version = File.join('lib', gem_name, 'version.rb')
      assert_exists_in_plugin(version)
      assert_file_contains version, <<-EOF
module Nesta
  module Plugin
    module My
      module Feature
        VERSION = '0.1.0'
      end
    end
  end
end
      EOF
    end
  end

  it 'creates skeleton code for the plugin in init.rb' do
    create_plugin do
      init = File.join('lib', gem_name, 'init.rb')
      assert_exists_in_plugin(init)

      assert_file_contains init, <<-MODULE
module Nesta
  module Plugin
    module My::Feature
        MODULE

      assert_file_contains init, 'helpers Nesta::Plugin::My::Feature::Helpers'
    end
  end
end
