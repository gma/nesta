require 'rake'

module Nesta
  module Static
    class Assets
      def initialize(build_dir)
        @build_dir = build_dir
      end

      def public_assets(public_folder)
        Rake::FileList["#{public_folder}/**/*"].tap do |assets|
          assets.exclude('~*')
          assets.exclude do |f|
            File.directory?(f)
          end
        end
      end

      def copy
        public_folder = Nesta::App.settings.public_folder
        public_assets(public_folder).each do |source|
          dest = File.join(@build_dir, source.sub(/^#{public_folder}\//, ''))
          task = Rake::FileTask.define_task(dest => source) do
            dest_dir = File.dirname(dest)
            FileUtils.mkdir_p(dest_dir) unless Dir.exist?(dest_dir)
            FileUtils.cp(source, dest_dir)
            puts "Copied #{source} to #{dest}"
          end
          task.invoke
        end
      end
    end
  end
end
