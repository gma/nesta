module Nesta
  module Plugins
    def self.load_local_plugins
      plugins = Dir.glob(File.expand_path('../plugins/*', File.dirname(__FILE__)))
      plugins.each { |path| require_plugin(path) }
    end

    private
      def self.require_plugin(path)
        require File.join(path, 'lib', File.basename(path))
      rescue LoadError => e
        $stderr.write("Couldn't load plugins/#{File.basename(path)}: #{e}\n")
      end
  end
end
