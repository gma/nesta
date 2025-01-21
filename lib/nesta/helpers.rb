module Nesta
  module View
    module Helpers
      def set_from_config(*variables)
        variables.each do |var|
          instance_variable_set("@#{var}", Nesta::Config.send(var))
        end
      end

      def set_from_page(*variables)
        variables.each do |var|
          instance_variable_set("@#{var}", @page.send(var))
        end
      end

      def no_widow(text)
        text.split[0...-1].join(" ") + "&nbsp;#{text.split[-1]}"
      end

      def set_common_variables
        @menu_items = Nesta::Menu.for_path('/')
        @site_title = Nesta::Config.title
        set_from_config(:title, :subtitle, :google_analytics_code)
        @heading = @title
      end

      def absolute_urls(text)
        text.gsub!(/(<a href=['"])\//, '\1' + path_to('/', uri: true))
        text
      end

      def nesta_atom_id_for_page(page)
        published = page.date.strftime('%Y-%m-%d')
        "tag:#{request.host},#{published}:#{page.abspath}"
      end

      def atom_id(page = nil)
        if page
          page.atom_id || nesta_atom_id_for_page(page)
        else
          "tag:#{request.host},2009:/"
        end
      end

      # Returns the current page's heading or the site's title, if we
      # don't have a current page, or the page doesn't have a heading
      # defined.
      #
      # Useful in templates that generate links to social sharing sites,
      # which need a suitable description for the page being shared or
      # bookmarked.
      #
      def heading_or_site_title
        @page && @page.heading
      rescue Nesta::HeadingNotSet
        @title
      end

      def format_date(date)
        date.strftime("%d %B %Y")
      end

      def local_stylesheet_link_tag(name)
        pattern = File.expand_path("views/#{name}.s{a,c}ss", Nesta::App.root)
        if Dir.glob(pattern).size > 0
          haml_tag :link, href: path_to("/css/#{name}.css"), rel: "stylesheet"
        end
      end

      def latest_articles(count = 8)
        Nesta::Page.find_articles[0..count - 1]
      end

      def article_summaries(articles)
        haml(:summaries, layout: false, locals: { pages: articles })
      end

      def articles_heading
        @page.metadata('articles heading') || "Articles on #{@page.heading}"
      end

      # Generates the full path to a given page, taking Rack routers and
      # reverse proxies into account.
      #
      # Takes an options hash with a single option called `uri`. Set it
      # to `true` if you'd like the publicly accessible URI for the
      # path, rather than just the path relative to the site's root URI.
      # The default is `false`.
      #
      #   path_to(page.abspath, uri: true)
      #
      def path_to(page_path, options = {})
        host = []
        if options[:uri]
          host << "http#{'s' if request.ssl?}://"
          if (request.env.include?("HTTP_X_FORWARDED_HOST") or
              request.port != (request.ssl? ? 443 : 80))
            host << request.host_with_port
          else
            host << request.host
          end
        end
        uri_parts = [host.join('')]
        uri_parts << request.script_name.to_s if request.script_name
        uri_parts << page_path
        File.join(uri_parts)
      end
    end
  end
end
