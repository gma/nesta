require File.expand_path('../command', File.dirname(__FILE__))

module Nesta
  module Commands
    module Plugin
      class Create
        include Command

        def initialize(*args)
          name = args.shift
          name.nil? && (raise UsageError.new('name not specified'))
          @name = name
          @gem_name = "nesta-plugin-#{name}"
          if File.exist?(@gem_name)
            raise RuntimeError.new("#{@gem_name} already exists")
          end
        end

        def lib_path(*parts)
          File.join(@gem_name, 'lib', *parts)
        end

        def modify_required_file
          File.open(lib_path("#{@gem_name}.rb"), 'w') do |file|
            file.write <<-EOF
require "#{@gem_name}/version"

Nesta::Plugin.register(__FILE__)
            EOF
          end
        end

        def modify_init_file
          module_name = @name.split('-').map { |name| name.capitalize }.join('::')
          File.open(lib_path(@gem_name, 'init.rb'), 'w') do |file|
            file.puts <<-EOF
module Nesta
  module Plugin
    module #{module_name}
      module Helpers
        # If your plugin needs any helper methods, add them here...
      end
    end
  end

  class App
    helpers Nesta::Plugin::#{module_name}::Helpers
  end
end
            EOF
          end
        end

        def specify_gem_dependency
          gemspec = File.join(@gem_name, "#{@gem_name}.gemspec")
          File.open(gemspec, 'r+') do |file|
            output = ''
            file.each_line do |line|
              if line =~ /^end/
                output << '  gem.add_dependency("nesta", ">= 0.9.11")' + "\n"
                output << '  gem.add_development_dependency("rake")' + "\n"
              end
              output << line
            end
            file.pos = 0
            file.print(output)
            file.truncate(file.pos)
          end
        end

        def execute
          run_process('bundle', 'gem', @gem_name)
          modify_required_file
          modify_init_file
          specify_gem_dependency
          Dir.chdir(@gem_name) { run_process('git', 'add', '.') }
        end
      end
    end
  end
end
