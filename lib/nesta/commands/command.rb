require File.expand_path('../process', File.dirname(__FILE__))

module Nesta
  module Commands
    class UsageError < RuntimeError; end

    module Command
      def update_config_yaml(pattern, replacement)
        configured = false
        File.open(Nesta::Config.yaml_path, 'r+') do |file|
          output = ''
          file.each_line do |line|
            if configured
              output << line
            else
              output << line.sub(pattern, replacement)
              configured = true if line =~ pattern
            end
          end
          output << "#{replacement}\n" unless configured
          file.pos = 0
          file.print(output)
          file.truncate(file.pos)
        end
      end
    end
  end
end
