module Nesta
  module Plugin
    class << self
      attr_accessor :loaded
    end
    self.loaded ||= []

    def self.register(path)
      name = File.basename(path, '.rb')
      prefix = 'nesta-plugin-'
      name.start_with?(prefix) || raise("Plugin names must match '#{prefix}*'")
      self.loaded << name
    end

    def self.initialize_plugins
      self.loaded.each { |name| require "#{name}/init" }
    end

    def self.load_local_plugins
      plugins = Dir.glob(File.expand_path('../plugins/*', File.dirname(__FILE__)))
      plugins.each { |path| require_local_plugin(path) }
    end

    private
      def self.require_local_plugin(path)
        Nesta.deprecated(
            'loading plugins from ./plugins', "convert #{path} to a gem")
        require File.join(path, 'lib', File.basename(path))
      rescue LoadError => e
        $stderr.write("Couldn't load plugins/#{File.basename(path)}: #{e}\n")
      end
  end
end
