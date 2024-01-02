def register_template_handler(class_name, *extensions)
  Tilt.register Tilt.const_get(class_name), *extensions
rescue LoadError
  # Only one of the Markdown processors needs to be available, so we can
  # safely ignore these load errors.
end

register_template_handler :MarukuTemplate, 'mdown', 'md'
register_template_handler :KramdownTemplate, 'mdown', 'md'
register_template_handler :RDiscountTemplate, 'mdown', 'md'
register_template_handler :RedcarpetTemplate, 'mdown', 'md'


module Nesta
  class MetadataParseError < RuntimeError; end

  class FileModel
    FORMATS = [:mdown, :md, :haml, :textile]
    @@model_cache = {}
    @@filename_cache = {}

    attr_reader :filename, :mtime

    class CaseInsensitiveHash < Hash
      def [](key)
        super(key.to_s.downcase)
      end
    end

    def self.model_path(basename = nil)
      Nesta::Config.content_path(basename)
    end

    def self.find_all
      file_pattern = File.join(model_path, "**", "*.{#{FORMATS.join(',')}}")
      Dir.glob(file_pattern).map do |path|
        relative = path.sub("#{model_path}/", "")
        load(relative.sub(/\.(#{FORMATS.join('|')})/, ""))
      end
    end

    def self.find_file_for_path(path)
      if ! @@filename_cache.has_key?(path)
        FORMATS.each do |format|
          [path, File.join(path, 'index')].each do |basename|
            filename = model_path("#{basename}.#{format}")
            if File.exist?(filename)
              @@filename_cache[path] = filename
              break
            end
          end
        end
      end
      @@filename_cache[path]
    end

    def self.needs_loading?(path, filename)
      @@model_cache[path].nil? || File.mtime(filename) > @@model_cache[path].mtime
    end

    def self.load(path)
      if (filename = find_file_for_path(path)) && needs_loading?(path, filename)
        @@model_cache[path] = self.new(filename)
      end
      @@model_cache[path]
    end

    def self.purge_cache
      @@model_cache = {}
      @@filename_cache = {}
    end

    def initialize(filename)
      @filename = filename
      @format = filename.split('.').last.to_sym
      if File.zero?(filename)
        @metadata = {}
        @markup = ''
      else
        @metadata, @markup = parse_file
      end
      @mtime = File.mtime(filename)
    end

    def ==(other)
      other.respond_to?(:path) && (self.path == other.path)
    end

    def index_page?
      @filename =~ /\/?index\.\w+$/
    end

    def abspath
      file_path = @filename.sub(self.class.model_path, '')
      if index_page?
        File.dirname(file_path)
      else
        File.join(File.dirname(file_path), File.basename(file_path, '.*'))
      end
    end

    def path
      abspath.sub(/^\//, '')
    end

    def permalink
      File.basename(path)
    end

    def layout
      (metadata('layout') || 'layout').to_sym
    end

    def template
      (metadata('template') || 'page').to_sym
    end

    def to_html(scope = Object.new)
      convert_to_html(@format, scope, markup)
    end

    def last_modified
      @last_modified ||= File.stat(@filename).mtime
    end

    def description
      metadata('description')
    end

    def keywords
      metadata('keywords')
    end

    def metadata(key)
      @metadata[key]
    end

    def flagged_as?(flag)
      flags = metadata('flags')
      flags && flags.split(',').map { |name| name.strip }.include?(flag)
    end

    def parse_metadata(first_paragraph)
      is_metadata = first_paragraph.split("\n").first =~ /^[\w ]+:/
      raise MetadataParseError unless is_metadata
      metadata = CaseInsensitiveHash.new
      first_paragraph.split("\n").each do |line|
        key, value = line.split(/\s*:\s*/, 2)
        next if value.nil?
        metadata[key.downcase] = value.chomp
      end
      metadata
    end

    private

    def markup
      @markup
    end

    def parse_file
      contents = File.open(@filename).read
    rescue Errno::ENOENT
      raise Sinatra::NotFound
    else
      first_paragraph, remaining = contents.split(/\r?\n\r?\n/, 2)
      begin
        return parse_metadata(first_paragraph), remaining
      rescue MetadataParseError
        return {}, contents
      end
    end

    def add_p_tags_to_haml(text)
      contains_tags = (text =~ /^\s*%/)
      if contains_tags
        text
      else
        text.split(/\r?\n/).inject('') do |accumulator, line|
          accumulator << "%p #{line}\n"
        end
      end
    end

    def convert_to_html(format, scope, text)
      text = add_p_tags_to_haml(text) if @format == :haml
      template = Tilt[format].new(renderer_config(@format)) { text }
      template.render(scope)
    end

    def renderer_config(format)
      {}
    end
  end
end
