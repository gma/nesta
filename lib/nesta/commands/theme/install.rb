require File.expand_path('../command', File.dirname(__FILE__))

module Nesta
  module Commands
    module Theme
      class Install
        include Command

        def initialize(*args)
          @url = args.shift
          @url.nil? && (raise UsageError.new('URL not specified'))
          options = args.shift || {}
        end

        def theme_name
          File.basename(@url, '.git').sub(/nesta-theme-/, '')
        end

        def execute
          run_process('git', 'clone', @url, "themes/#{theme_name}")
          FileUtils.rm_r(File.join("themes/#{theme_name}", '.git'))
          enable
        end

        def enable
          Enable.new(theme_name).execute
        end
      end
    end
  end
end
