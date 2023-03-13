require 'rake'

require_relative './html_file'

module Nesta
  module Static
    class SiteContent
      def initialize(build_dir, logger = nil)
        @build_dir = build_dir
        @logger = logger
        @app = Nesta::App.new
      end

      def log(message)
        @logger.call(message) if @logger
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

      def render_pages
        set_app_root
        Nesta::Page.find_all.each do |page|
          target = HtmlFile.new(@build_dir, page).filename
          source = page.filename
          task = Rake::FileTask.define_task(target => source) do
            http_code, markup = render_page(page, target)
            save_markup(target, markup)
          end
          task.invoke
        end
      end

      def rack_environment(page)
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
      end

      def render_page(page, html_path)
        http_code, headers, body = @app.call(rack_environment(page))
        if http_code != 200
          raise RuntimeError, "Can't render #{html_path} from #{page.filename}"
        end
        log("Rendered #{html_path}: #{http_code}")
        [http_code, body.join]
      end

      def save_markup(filename, content)
        FileUtils.mkdir_p(File.dirname(filename))
        open(filename, 'w') { |output| output.puts(content) }
      end
    end
  end
end
