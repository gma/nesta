module Nesta
  module Commands
    class Template
      def initialize(filename)
        @filename = filename
      end

      def template_path
        dir = File.expand_path('../../../templates', File.dirname(__FILE__))
        File.join(dir, @filename)
      end

      def copy_to(dest, context)
        FileUtils.mkdir_p(File.dirname(dest))
        template = ERB.new(File.read(template_path), nil, "-")
        File.open(dest, 'w') { |file| file.puts template.result(context) }
      end
    end
  end
end
