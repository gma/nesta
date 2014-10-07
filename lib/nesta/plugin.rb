module Nesta
  module Plugin
    class << self
      attr_accessor :loaded
    end
    self.loaded ||= []

    def self.register(path)
      # Maintain compatibility with plugins that pass filename
      path = File.basename(path, '.rb') if path.end_with? '.rb'
      prefix = 'nesta-plugin-'
      plugin_name = path.tr('/', '-')
      plugin_name.start_with?(prefix) || raise("Plugin names must match '#{prefix}*'")
      self.loaded << path
    end

    def self.initialize_plugins
      self.loaded.each { |name| require "#{name}/init" }
    end

    def self.load_local_plugins
      # This approach is deprecated; plugins should now be distributed
      # as gems. See http://nestacms.com/docs/plugins/writing-plugins
      plugins = Dir.glob(File.expand_path('../plugins/*', File.dirname(__FILE__)))
      plugins.each { |path| require_local_plugin(path) }
    end

    def self.require_local_plugin(path)
      Nesta.deprecated(
          'loading plugins from ./plugins', "convert #{path} to a gem")
      require File.join(path, 'lib', File.basename(path))
    rescue LoadError => e
      $stderr.write("Couldn't load plugins/#{File.basename(path)}: #{e}\n")
    end
    private_class_method :require_local_plugin
  end
end
