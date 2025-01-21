module Nesta
  module Commands
    module Theme
      class Install
        def initialize(*args)
          @url = args.shift
          @url.nil? && (raise UsageError.new('URL not specified'))
        end

        def theme_name
          File.basename(@url, '.git').sub(/nesta-theme-/, '')
        end

        def execute(process)
          process.run('git', 'clone', @url, "themes/#{theme_name}")
          FileUtils.rm_rf(File.join("themes/#{theme_name}", '.git'))
          enable(process)
        end

        def enable(process)
          Enable.new(theme_name).execute(process)
        end
      end
    end
  end
end
