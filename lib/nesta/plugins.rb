module Nesta
  module Plugins
    def self.load_local_plugins
      plugins = Dir.glob(File.expand_path('../plugins/*', File.dirname(__FILE__)))
      plugins.each { |plugin| require_plugin(plugin) }
    end

    private
      def self.require_plugin(plugin)
        require File.join(plugin, 'lib', File.basename(plugin))
      rescue LoadError => e
        $stderr.write("Couldn't load plugins/#{File.basename(plugin)}: #{e}\n")
      end
  end
end
