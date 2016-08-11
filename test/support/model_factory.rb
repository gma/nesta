module ModelFactory
  class FileModelWriter
    def initialize(type, data = {})
      @type = type
      @data = data
    end

    def model_class
      Nesta::FileModel
    end

    def instantiate_model
      model_class.new(filename)
    end

    def extension
      data.fetch(:ext, 'mdown')
    end

    def filename
      File.join(model_class.model_path, "#{data[:path]}.#{extension}")
    end

    def sequence_prefix
      'file-'
    end

    def default_data
      { path: default_path }
    end

    def default_path
      sequence_prefix + ModelFactory.next_sequence_number.to_s
    end

    def data
      if @memoized_data.nil?
        @memoized_data = default_data
        if @memoized_data.has_key?(:metadata)
          @memoized_data[:metadata].merge!(@data.delete(:metadata) || {})
        end
        @memoized_data.merge!(@data)
      end
      @memoized_data
    end

    def write
      metadata = data[:metadata] || {}
      metatext = metadata.map { |key, value| "#{key}: #{value}" }.join("\n")
      contents =<<-EOF
#{metatext}

#{heading}#{data[:content]}
      EOF
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, 'w') { |file| file.write(contents) }
      yield(filename) if block_given?
    end

    def heading
      return '' unless data[:heading]
      prefix = {
        'haml' => "%div\n  %h1",
        'textile' => "<div>\nh1."
      }.fetch(data[:ext], '# ')
      "#{prefix} #{data[:heading]}\n\n"
    end
  end

  class PageWriter < FileModelWriter
    def model_class
      Nesta::Page
    end

    def sequence_prefix
      'page-'
    end

    def default_data
      path = default_path
      { path: path, heading: heading_from_path(path) }
    end

    def heading_from_path(path)
      File.basename(path).sub('-', ' ').capitalize
    end
  end

  class ArticleWriter < PageWriter
    def sequence_prefix
      'articles/page-'
    end

    def default_data
      path = default_path
      {
        path: path,
        heading: heading_from_path(path),
        content: 'Content goes here',
        metadata: {
          'date' => '29 December 2008'
        }
      }
    end
  end

  class CategoryWriter < PageWriter
    def sequence_prefix
      'categories/page-'
    end

    def default_data
      path = default_path
      {
        path: path,
        heading: heading_from_path(path),
        content: 'Content goes here'
      }
    end
  end

  @@sequence = 0
  def self.next_sequence_number
    @@sequence += 1
  end

  def before_setup
    # This is a minitest hook. We reset file sequence number at the
    # start of each test so that we can automatically generate a unique
    # path for each file we create within a test.
    @@sequence = 0
  end

  def create(type, data = {}, &block)
    file_writer = writer_class(type).new(type, data)
    file_writer.write(&block)
    file_writer.instantiate_model
  end

  def write_menu_item(indent, file, menu_item)
    if menu_item.is_a?(Array)
      indent.sub!(/^/, '  ')
      menu_item.each { |path| write_menu_item(indent, file, path) }
      indent.sub!(/^  /, '')
    else
      file.write("#{indent}#{menu_item}\n")
    end
  end

  def create_menu(menu_text)
    file = filename(Nesta::Config.content_path, 'menu', :txt)
    File.open(file, 'w') { |file| file.write(menu_text) }
  end

  def create_content_directories
    FileUtils.mkdir_p(Nesta::Config.page_path)
    FileUtils.mkdir_p(Nesta::Config.attachment_path)
  end

  private
  def filename(directory, basename, extension = :mdown)
    File.join(directory, "#{basename}.#{extension}")
  end

  def writer_class(type)
    camelcased_type = type.to_s.gsub(/(?:^|_)(\w)/) { $1.upcase }
    ModelFactory.const_get(camelcased_type + 'Writer')
  end
end
