require 'rake'

require_relative '../static/assets'
require_relative '../static/site_content'

module Nesta
  module Commands
    class Build
      DEFAULT_DESTINATION = "dist"

      def initialize(*args)
        @build_dir = args.shift || DEFAULT_DESTINATION
        if @build_dir == Nesta::App.settings.public_folder
          raise RuntimeError.new("#{@build_dir} is already used, for assets")
        end
      end

      def execute(process)
        logger = Proc.new { |message| puts message }
        Nesta::Static::SiteContent.new(@build_dir, logger).render_pages
        Nesta::Static::Assets.new(@build_dir, logger).copy
      end
    end
  end
end
