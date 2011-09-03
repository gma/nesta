module ModelFactory
  include FixtureHelper

  def create_page(options)
    extension = options[:ext] || :mdown
    path = filename(Nesta::Config.page_path, options[:path], extension)
    if options[:translations]
      create_translated_file(path, options, options[:translations])
    else
      create_file(path, options)
    end
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

    def metatext_for(metadata)
      (metadata || {}).map { |key, value| "#{key}: #{value}" }.join("\n")
    end

    def contents_for(options)
      heading = options[:heading] ? heading(options) : ''
      <<-EOF
#{metatext_for(options[:metadata])}

#{heading}#{options[:content]}
      EOF
    end

    def create_dirs(path)
      create_content_directories
      FileUtils.mkdir_p(File.dirname(path))
    end      

    def create_file(path, options = {})
      create_dirs(path)
      File.open(path, 'w') { |file| file.write(contents_for(options)) }
    end

    def create_translated_file(path, options, translations)
      create_dirs(path)
      File.open(path, 'w') do |file|
        file.write(metatext_for(options[:metadata]) + "\n")
        translations.each_pair do |locale, locale_options|
          locale_options[:metadata] = (locale_options[:metadata] || {}).to_a
          locale_options[:metadata].unshift([:language, locale])
          file.write(contents_for(locale_options))
        end
      end
    end
end
