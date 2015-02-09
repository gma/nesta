require File.expand_path('command', File.dirname(__FILE__))

module Nesta
  module Commands
    class Edit
      include Command

      def initialize(*args)
        @filename = Nesta::Config.page_path(args.shift)
      end

      def execute
        editor = ENV.fetch('EDITOR')
      rescue IndexError
        $stderr.puts "No editor: set EDITOR environment variable"
      else
        run_process(editor, @filename)
      end
    end
  end
end
