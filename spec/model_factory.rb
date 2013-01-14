module ModelFactory
  def create_page(options)
    extension = options[:ext] || :mdown
    path = filename(Nesta::Config.page_path, options[:path], extension)
    create_file(path, options)
    yield(path) if block_given?
    Nesta::Page.new(path)
  end

  def create_article(options = {}, &block)
    o = {
      :path => 'article-prefix/my-article',
      :heading => 'My article',
      :content => 'Content goes here',
      :metadata => {
        'date' => '29 December 2008'
      }.merge(options.delete(:metadata) || {})
    }.merge(options)
    create_page(o, &block)
  end

  def create_category(options = {}, &block)
    o = {
      :path => 'category-prefix/my-category',
      :heading => 'My category',
      :content => 'Content goes here'
    }.merge(options)
    create_page(o, &block)
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

  def delete_page(type, permalink, extension)
    file = filename(Nesta::Config.page_path, permalink, extension)
    FileUtils.rm(file)
  end

  def create_content_directories
    FileUtils.mkdir_p(Nesta::Config.page_path)
    FileUtils.mkdir_p(Nesta::Config.attachment_path)
  end

  def mock_file_stat(method, filename, time)
    stat = mock(:stat)
    stat.stub!(:mtime).and_return(Time.parse(time))
    File.send(method, :stat).with(filename).and_return(stat)
  end

  private
    def filename(directory, basename, extension = :mdown)
      File.join(directory, "#{basename}.#{extension}")
    end

    def heading(options)
      prefix = case options[:ext]
        when :haml
          "%div\n  %h1"
        when :textile
          "<div>\nh1."
        else
          '# '
        end
      "#{prefix} #{options[:heading]}\n\n"
    end

    def create_file(path, options = {})
      create_content_directories
      metadata = options[:metadata] || {}
      metatext = metadata.map { |key, value| "#{key}: #{value}" }.join("\n")
      heading = options[:heading] ? heading(options) : ''
      contents =<<-EOF
#{metatext}

#{heading}#{options[:content]}
      EOF
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') { |file| file.write(contents) }
    end
end
