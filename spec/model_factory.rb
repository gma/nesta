module ModelFactory

  FIXTURE_DIR = File.join(File.dirname(__FILE__), "fixtures")

  def stub_config_key(key, value)
    @config ||= {}
    @config[key] = value
  end
  
  def stub_env_config_key(key, value)
    @config ||= {}
    @config["test"] ||= {}
    @config["test"][key] = value
  end

  def stub_configuration
    stub_config_key("title", "My blog")
    stub_config_key("subtitle", "about stuff")
    stub_config_key("description", "great web site")
    stub_config_key("keywords", "home, page")
    stub_env_config_key("content", FIXTURE_DIR)
    Nesta::Configuration.stub!(:configuration).and_return(@config)
  end

  def create_page(options)
    path = filename(Nesta::Configuration.page_path, options[:path])
    create_file(path, options)
    yield(path) if block_given?
    Page.new(path)
  end
  
  def create_article(options = {}, &block)
    o = {
      :path => "article-prefix/my-article",
      :title => "My article",
      :content => "Content goes here",
      :metadata => {
        "date" => "29 December 2008"
      }.merge(options.delete(:metadata) || {})
    }.merge(options)
    create_page(o, &block)
  end
  
  def create_category(options = {}, &block)
    o = {
      :path => "category-prefix/my-category",
      :title => "My category",
      :content => "Content goes here"
    }.merge(options)
    create_page(o, &block)
  end
  
  def create_comment(options = {})
    o = {
      :metadata => {
        "article" => "article-prefix/my-article",
        "date" => "Sun Nov 23 13:15:47 +0000 2008",
        "author" => "Fred Bloggs",
        "author email" => "fred@bloggs.com",
        "author url" => "http://bloggs.com/~fred"
      }.merge(options.delete(:metadata) || {}),
      :content => "Great article."
    }.merge(options)
    basename = Comment.basename(
        DateTime.parse(o[:metadata]["date"]), o[:metadata]["author"])
    path = filename(Nesta::Configuration.comment_path, basename)
    create_file(path, o)
    yield(path) if block_given?
  end
  
  def create_menu(*paths)
    menu_file = filename(Nesta::Configuration.content_path, "menu", :txt)
    File.open(menu_file, "w") do |file|
      paths.each { |p| file.write("#{p}\n") }
    end
  end
  
  def delete_page(type, permalink)
    FileUtils.rm(filename(Nesta::Configuration.page_path, permalink))
  end
  
  def remove_fixtures
    FileUtils.rm_r(FIXTURE_DIR, :force => true)
  end
  
  def create_content_directories
    FileUtils.mkdir_p(Nesta::Configuration.page_path)
    FileUtils.mkdir_p(Nesta::Configuration.attachment_path)
    FileUtils.mkdir_p(Nesta::Configuration.comment_path)
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
    
    def create_file(path, options = {})
      create_content_directories
      metadata = options[:metadata] || {}
      metatext = metadata.map { |key, value| "#{key}: #{value}" }.join("\n")
      title = options[:title] ? "# #{options[:title]}\n\n" : ""
      contents =<<-EOF
#{metatext}

#{title}#{options[:content]}
      EOF

      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "w") { |file| file.write(contents) }
    end
end
