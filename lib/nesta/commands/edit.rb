module Nesta
  module Commands
    class Edit
      def initialize(*args)
        @filename = Nesta::Config.page_path(args.shift)
      end

      def execute(process)
        editor = ENV.fetch('EDITOR')
      rescue IndexError
        $stderr.puts "No editor: set EDITOR environment variable"
      else
        process.run(editor, @filename)
      end
    end
  end
end
