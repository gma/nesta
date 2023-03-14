require 'rake'

require_relative '../static/assets'
require_relative '../static/site_content'

module Nesta
  module Commands
    class Build
      DEFAULT_DESTINATION = "dist"

      def initialize(build_dir = nil, options = {})
        @build_dir = build_dir || DEFAULT_DESTINATION
        if @build_dir == Nesta::App.settings.public_folder
          raise RuntimeError.new("#{@build_dir} is already used, for assets")
        end
        @domain = options['domain'] || Nesta::Config.fetch(:domain, 'localhost')
      end

      def execute(process)
        logger = Proc.new { |message| puts message }
        site = Nesta::Static::SiteContent.new(@build_dir, @domain, logger)
        site.render_pages
        site.render_not_found
        site.render_sitemap
        Nesta::Static::Assets.new(@build_dir, logger).copy
      end
    end
  end
end
