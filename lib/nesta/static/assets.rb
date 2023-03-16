require 'rake'

module Nesta
  module Static
    class Assets
      def initialize(build_dir, logger = nil)
        @build_dir = build_dir
        @logger = logger
      end

      def copy_attachments
        dest_basename = File.basename(Nesta::Config.attachment_path)
        dest_dir = File.join(@build_dir, dest_basename)
        copy_file_tree(Nesta::Config.attachment_path, dest_dir)
      end

      def copy_public_folder
        copy_file_tree(Nesta::App.settings.public_folder, @build_dir)
      end

      private

      def log(message)
        @logger.call(message) if @logger
      end

      def copy_file_tree(source_dir, dest_dir)
        files_in_tree(source_dir).each do |file|
          target = File.join(dest_dir, file.sub(/^#{source_dir}\//, ''))
          task = Rake::FileTask.define_task(target => file) do
            target_dir = File.dirname(target)
            FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)
            FileUtils.cp(file, target_dir)
            log("Copied #{file} to #{target}")
          end
          task.invoke
        end
      end

      def files_in_tree(directory)
        Rake::FileList["#{directory}/**/*"].tap do |assets|
          assets.exclude('~*')
          assets.exclude do |f|
            File.directory?(f)
          end
        end
      end
    end
  end
end
