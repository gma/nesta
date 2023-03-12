require 'rake'

module Nesta
  module Commands
    class Build
      DEFAULT_DESTINATION = "dist"

      def initialize(*args)
        @build_dir = args.shift || DEFAULT_DESTINATION
        if @build_dir == Nesta::App.settings.public_folder
          raise RuntimeError.new("#{@build_dir} is already used, for assets")
        end
        @app = Nesta::App.new
      end

      def set_app_root
        root = ::File.expand_path('.')
        ['Gemfile', ].each do |expected|
          if ! File.exist?(File.join(root, 'config', 'config.yml'))
            message = "is this a Nesta site? (expected './#{expected}')"
            raise RuntimeError, message
          end
        end
        Nesta::App.root = root
      end

      def page_shares_path_with_directory?(dir, base_without_ext)
        Dir.exist?(File.join(dir, base_without_ext))
      end

      def html_filename(page)
        dir, base = File.split(page.filename)
        base_without_ext = File.basename(base, File.extname(base))
        subdir = dir.sub(/^#{Nesta::Config.page_path}/, '')
        path = File.join(@build_dir, subdir, base_without_ext)
        if page_shares_path_with_directory?(dir, base_without_ext)
          File.join(path, 'index.html')
        else
          path + '.html'
        end
      end

      def render_page(page, html_file)
        http_code, headers, body = @app.call(
          {
            'REQUEST_METHOD' => 'GET',
            'SCRIPT_NAME' => '',
            'PATH_INFO' => page.abspath,
            'QUERY_STRING' => '',
            'SERVER_NAME' => 'localhost',
            'SERVER_PROTOCOL' => 'https',
            'rack.url_scheme' => 'https',
            'rack.input' => StringIO.new,
            'rack.errors' => STDERR
          }
        )
        if http_code != 200
          raise RuntimeError, "Can't render #{html_file} from #{page.filename}"
        end
        puts "Rendered #{html_file}: #{http_code}"
        [http_code, body.join]
      end

      def save_markup(filename, content)
        FileUtils.mkdir_p(File.dirname(filename))
        open(filename, 'w') { |output| output.puts(content) }
      end

      def execute(process)
        set_app_root
        Nesta::Page.find_all.each do |page|
          html_file = html_filename(page)
          task = Rake::FileTask.define_task(html_file => page.filename) do
            http_code, markup = render_page(page, html_file)
            save_markup(html_file, markup)
          end
          task.invoke
        end
      end
    end
  end
end
