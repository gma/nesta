require File.expand_path('../command', File.dirname(__FILE__))

module Nesta
  module Commands
    module Theme
      class Install
        include Command

        def initialize(*args)
          url = args.shift
          options = args.shift || {}
          url.nil? && (raise UsageError.new('URL not specified'))
          @url = url
          @name = File.basename(url, '.git').sub(/nesta-theme-/, '')
        end

        def execute
          run_process('git', 'clone', @url, "themes/#{@name}")
          FileUtils.rm_r(File.join("themes/#{@name}", '.git'))
          enable
        end

        def enable
          Enable.new(@name).execute
        end
      end
    end
  end
end
