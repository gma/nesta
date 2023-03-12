require 'rake'

module Nesta
  module Commands
    class Build
      DEFAULT_DESTINATION = "dist"

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

      class SiteContent
        def initialize(build_dir)
          @build_dir = build_dir
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
          puts "Rendered #{html_path}: #{http_code}"
          [http_code, body.join]
        end

        def save_markup(filename, content)
          FileUtils.mkdir_p(File.dirname(filename))
          open(filename, 'w') { |output| output.puts(content) }
        end
      end

      def initialize(*args)
        @build_dir = args.shift || DEFAULT_DESTINATION
        if @build_dir == Nesta::App.settings.public_folder
          raise RuntimeError.new("#{@build_dir} is already used, for assets")
        end
      end

      def execute(process)
        SiteContent.new(@build_dir).render_pages
      end
    end
  end
end
