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
  end
end
