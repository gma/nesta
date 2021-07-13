require File.expand_path('../command', File.dirname(__FILE__))

module Nesta
  module Commands
    module Demo
      class Content
        include Command

        @demo_repository = 'git://github.com/gma/nesta-demo-content.git'
        class << self
          attr_accessor :demo_repository
        end

        def initialize(*args)
          @dir = 'content-demo'
        end

        def clone_or_update_repository(process)
          path = Nesta::Path.local(@dir)
          if File.exist?(path)
            FileUtils.cd(path) { process.run('git', 'pull', 'origin', 'master') }
          else
            process.run('git', 'clone', self.class.demo_repository, path)
          end
        end

        def exclude_path
          Nesta::Path.local('.git/info/exclude')
        end

        def in_git_repo?
          File.directory?(Nesta::Path.local('.git'))
        end

        def demo_repo_ignored?
          File.read(exclude_path).split.any? { |line| line == @dir }
        rescue Errno::ENOENT
          false
        end

        def configure_git_to_ignore_repo
          if in_git_repo? && ! demo_repo_ignored?
            FileUtils.mkdir_p(File.dirname(exclude_path))
            File.open(exclude_path, 'a') { |file| file.puts @dir }
          end
        end

        def execute(process)
          clone_or_update_repository(process)
          configure_git_to_ignore_repo
          update_config_yaml(/^\s*#?\s*content:.*/, "content: #{@dir}")
        end
      end
    end
  end
end
