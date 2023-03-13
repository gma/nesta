require 'rake'

require_relative './html_file'

module Nesta
  module Static
    class SiteContent
      def initialize(build_dir, logger = nil)
        @build_dir = build_dir
        @logger = logger
        @app = Nesta::App.new
        set_app_root
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
        Nesta::Page.find_all.each do |page|
          target = HtmlFile.new(@build_dir, page).filename
          source = page.filename
          task = Rake::FileTask.define_task(target => source) do
            save_markup(target, render_page(page.abspath, target, source))
          end
          task.invoke
        end
      end

      def render_not_found
        path_info = '/404'
        source = 'no-such-file.md'
        target = File.join(@build_dir, '404.html')
        markup = render_page(path_info, target, source, expected_code: 404)
        save_markup(target, markup)
      end

      def render_sitemap
        filename = File.join(@build_dir, 'sitemap.xml')
        save_markup(filename, render_page('/sitemap.xml', filename, 'site'))
      end

      def rack_environment(abspath)
        {
          'REQUEST_METHOD' => 'GET',
          'SCRIPT_NAME' => '',
          'PATH_INFO' => abspath,
          'QUERY_STRING' => '',
          'SERVER_NAME' => 'localhost',
          'SERVER_PROTOCOL' => 'https',
          'rack.url_scheme' => 'https',
          'rack.input' => StringIO.new,
          'rack.errors' => STDERR
        }
      end

      def render_page(abspath, filename, description, expected_code: 200)
        http_code, headers, body = @app.call(rack_environment(abspath))
        if http_code != expected_code
          raise RuntimeError, "Can't render #{filename} from #{description}"
        end
        body.join
      end

      def save_markup(filename, content)
        FileUtils.mkdir_p(File.dirname(filename))
        if (! File.exist?(filename)) || (open(filename, 'r').read != content)
          open(filename, 'w') { |output| output.puts(content) }
          log("Rendered #{filename}")
        end
      end
    end
  end
end
