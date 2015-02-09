module Nesta
  module Commands
    class UsageError < RuntimeError; end

    module Command
      def run_process(*args)
        system(*args)
        if ! $?.success?
          message = if $?.exitstatus == 127
                      "#{args[0]} not found"
                    else
                      "'#{args.join(' ')}' failed with status #{$?.exitstatus}"
                    end
          $stderr.puts "Error: #{message}"
          exit 1
        end
      end

      def fail(message)
        $stderr.puts "Error: #{message}"
        exit 1
      end

      def template_root
        File.expand_path('../../../templates', File.dirname(__FILE__))
      end

      def copy_template(src, dest)
        FileUtils.mkdir_p(File.dirname(dest))
        template = ERB.new(File.read(File.join(template_root, src)))
        File.open(dest, 'w') { |file| file.puts template.result(binding) }
      end

      def copy_templates(templates)
        templates.each { |src, dest| copy_template(src, dest) }
      end

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
