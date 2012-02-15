module Nesta
  module Formats
    @preferred_mappings = Hash.new
    @template_mappings = Hash.new { |h, k| h[k] = [] }

    # The set of extensions (without the leading dot) as symbols
    def self.extensions
      @template_mappings.keys
    end

    # Normalizes string extensions to symbols, stripping the leading dot. If passed a symbol, assumes it has already been trimmed.
    def self.normalize(ext)
      (ext.is_a? Symbol) ? ext : ext.to_s.downcase.sub(/^\./, '').to_sym
    end

    # Register a template implementation by file extension.
    def self.register(template_class, *extensions)
      extensions.each do |ext|
        ext = normalize(ext)
        @template_mappings[ext].unshift(template_class).uniq!
      end
    end
    
    # Makes a template class preferred for the given file extensions. If you
    # don't provide any extensions, it will be preferred for all its already
    # registered extensions:
    #
    #   # Prefer MarkdownFormat for its registered file extensions:
    #   Nesta::Formats.prefer(Nesta::Formats:MarkdownFormat)
    #
    #   # Prefer MarkdownFormat only for the .md extensions:
    #   Nesta::Formats.prefer(Nesta::Formats:MarkdownFormat, '.md')
    def self.prefer(template_class, *extensions)
      if extensions.empty?
        @template_mappings.each do |ext, klasses|
          @preferred_mappings[ext] = template_class if klasses.include? template_class
        end
      else
        extensions.each do |ext|
          ext = normalize(ext)
          register(template_class, ext)
          @preferred_mappings[ext] = template_class
        end
      end
    end

    # Returns true when a template exists on an exact match of the provided file extension
    def self.registered?(ext)
      ext = normalize(ext)
      @template_mappings.key?(ext) && !@template_mappings[ext].empty?
    end

    # Lookup a class for the given extension
    # Return nil when no implementation is found.
    def self.[](ext)
       pattern = normalize(ext)

       # Try to find a preferred engine.
       preferred_klass = @preferred_mappings[pattern]
       return preferred_klass if preferred_klass

       # Fall back to the general list of mappings.
       klasses = @template_mappings[pattern]

       # Try to find the first non-null class. 
       template = klasses.detect do |klass|
         not klass.nil?
       end
       
       # We don't provide a method for engine initialization like Tilt does - it doubles code complexity and we don't have a use-case yet.
       # Using static methods may be the wrong approach, but since Tilt is handling all the heavy lifting, I don't see one on the horizon.

       return template if template
     end
     
     
     class MarkdownFormat
       def self.heading (markup) markup =~ /^#\s*(.*?)(\s*#+|$)/
         Regexp.last_match(1)
       end
       
       def self.body (markup) markup.sub(/^#[^#].*$\r?\n(\r?\n)?/, '')  end
     end
     
     class HamlFormat
         def self.heading (markup) markup =~  /^\s*%h1\s+(.*)/
           Regexp.last_match(1)
         end
         def self.body (markup) markup.sub(/^\s*%h1\s+.*$\r?\n(\r?\n)?/, '') end
     end
     
     class TextileFormat
         def self.heading (markup) markup =~  /^\s*h1\.\s+(.*)/
           Regexp.last_match(1)
         end

         def self.body (markup) markup.sub(/^\s*h1\.\s+.*$\r?\n(\r?\n)?/, '') end
    end
     
     class HtmlFormat
         def self.heading (markup) markup =~ /^\s*<h1[^><]*>(.*?)<\/h1>/
           Regexp.last_match(1)
         end

         def self.body (markup) markup.sub(/^\s*<h1[^><]*>.*?<\/h1>\s*/, '') end
     end
     
     register MarkdownFormat, :mdown, :md
     register HamlFormat, :haml
     register TextileFormat, :textile
     register HtmlFormat, :htmf
  end
end