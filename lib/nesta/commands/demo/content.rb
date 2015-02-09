require File.expand_path('../command', File.dirname(__FILE__))

module Nesta
  module Commands
    module Demo
      class Content
        include Command

        def initialize(*args)
          @dir = 'content-demo'
        end

        def clone_or_update_repository
          repository = 'git://github.com/gma/nesta-demo-content.git'
          path = Nesta::Path.local(@dir)
          if File.exist?(path)
            FileUtils.cd(path) { run_process('git', 'pull', 'origin', 'master') }
          else
            run_process('git', 'clone', repository, path)
          end
        end

        def configure_git_to_ignore_repo
          excludes = Nesta::Path.local('.git/info/exclude')
          if File.exist?(excludes) && File.read(excludes).scan(@dir).empty?
            File.open(excludes, 'a') { |file| file.puts @dir }
          end
        end

        def execute
          clone_or_update_repository
          configure_git_to_ignore_repo
          update_config_yaml(/^\s*#?\s*content:.*/, "content: #{@dir}")
        end
      end
    end
  end
end
