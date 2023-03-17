module Nesta
  module Static
    class HtmlFile
      def initialize(build_dir, page)
        @build_dir = build_dir
        @content_path = page.filename
      end

      def page_shares_path_with_directory?(dir, base_without_ext)
        Dir.exist?(File.join(dir, base_without_ext))
      end

      def filename
        dir, base = File.split(@content_path)
        base_without_ext = File.basename(base, File.extname(base))
        subdir = dir.sub(/^#{Nesta::Config.page_path}/, '')
        path = File.join(@build_dir, subdir, base_without_ext)
        if page_shares_path_with_directory?(dir, base_without_ext)
          File.join(path, 'index.html')
        else
          path + '.html'
        end
      end
    end
  end
end
