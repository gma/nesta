require "rubygems"
require "spec"
require "sinatra"
require "sinatra/test/rspec"
require "rspec_hpricot_matchers"

Spec::Runner.configure do |config|
  config.include(RspecHpricotMatchers)
end

set_options :views => File.join(File.dirname(__FILE__), "..", "views"),
            :public => File.join(File.dirname(__FILE__), "..", "public")

require File.join(File.dirname(__FILE__), "..", "app")

module ModelFactory

  FIXTURE_DIR = File.join(File.dirname(__FILE__), "fixtures")

  def stub_config_key(key, value)
    @config ||= {}
    @config[key] = value
  end

  def stub_configuration
    stub_config_key("blog", { "title" => "My blog", "subheading" => "about stuff" })
    stub_config_key("content", File.join(File.dirname(__FILE__), ["fixtures"]))
    Nesta::Configuration.stub!(:configuration).and_return(@config)
  end

  def create_article_with_metadata
    metadata = {
      "date" => "29 December 2008",
      "summary" => 'Summary text\n\nwith two paragraphs',
      "read more" => "Continue please"
    }
    create_article(:metadata => metadata)
    metadata
  end

  def create_article(options = {})
    o = {
      :permalink => "my-article",
      :title => "My article",
      :content => "Content goes here"
    }.merge(options)
    create_file(Nesta::Configuration.article_path, o)
  end
  
  def create_category(options = {})
    o = {
      :permalink => "my-category",
      :title => "My category",
      :content => "Content goes here"
    }.merge(options)
    create_file(Nesta::Configuration.category_path, o)
  end
  
  def create_pages(type, *titles)
    titles.each do |title|
      permalink = title.gsub(" ", "-").downcase
      send "create_#{type}", { :title => title, :permalink => permalink }
    end
  end
  
  def delete_page(type, permalink)
    path = Nesta::Configuration.send "#{type}_path"
    FileUtils.rm(File.join(path, "#{permalink}.mdown"))
  end
  
  def remove_fixtures
    FileUtils.rm_r(FIXTURE_DIR, :force => true)
  end
  
  private
    def create_file(path, options = {})
      create_content_directories
      metadata = options[:metadata] || {}
      metatext = metadata.map { |key, value| "#{key}: #{value}" }.join("\n")
      metatext += "\n\n" unless metatext.empty?
      contents =<<-EOF
#{metatext}# #{options[:title]}

#{options[:content]}
      EOF

      File.open(File.join(path, "#{options[:permalink]}.mdown"), "w") do |file|
        file.write(contents)
      end
    end

    def create_content_directories
      FileUtils.mkdir_p(Nesta::Configuration.article_path)
      FileUtils.mkdir_p(Nesta::Configuration.category_path)
    end
end

