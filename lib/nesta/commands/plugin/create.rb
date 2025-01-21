module Nesta
  module Commands
    module Plugin
      class Create
        def initialize(*args)
          name = args.shift
          name.nil? && (raise UsageError, 'name not specified')
          @name = name
          @gem_name = "nesta-plugin-#{name}"
          if File.exist?(@gem_name)
            raise "#{@gem_name} already exists"
          end
        end

        def lib_path(*parts)
          File.join(@gem_name, 'lib', *parts)
        end

        def module_name
          module_names.join('::')
        end

        def nested_module_definition_with_version
          indent_with = '  '

          lines = module_names.map { |name| "module #{name}" }
          indent_levels = 0.upto(module_names.size - 1).to_a

          lines << "VERSION = '0.1.0'"
          indent_levels << module_names.size

          (module_names.size - 1).downto(0).each do |indent_level|
            lines << 'end'
            indent_levels << indent_level
          end

          code = []
          lines.each_with_index do |line, i|
            code << indent_with * (indent_levels[i] + 2) + line
          end
          code.join("\n")
        end

        def make_directories
          FileUtils.mkdir_p(File.join(@gem_name, 'lib', @gem_name))
        end

        def gem_path(path)
          File.join(@gem_name, path)
        end

        def execute(process)
          make_directories
          {
            'plugins/README.md' => gem_path('README.md'),
            'plugins/gitignore' => gem_path('.gitignore'),
            'plugins/plugin.gemspec' => gem_path("#{@gem_name}.gemspec"),
            'plugins/Gemfile' => gem_path('Gemfile'),
            'plugins/lib/required.rb' => gem_path("lib/#{@gem_name}.rb"),
            'plugins/lib/version.rb' => gem_path("lib/#{@gem_name}/version.rb"),
            'plugins/lib/init.rb' => gem_path("lib/#{@gem_name}/init.rb"),
            'plugins/Rakefile' => gem_path('Rakefile')
          }.each do |src, dest|
            Nesta::Commands::Template.new(src).copy_to(dest, binding)
          end
          Dir.chdir(@gem_name) do
            process.run('git', 'init')
            process.run('git', 'add', '.')
          end
        end

        private
          def module_names
            @name.split('-').map { |name| name.capitalize }
          end
      end
    end
  end
end
