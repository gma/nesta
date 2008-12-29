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

require File.join(File.dirname(__FILE__), "..", "nesta")

module ArticleFactory

  FIXTURE_DIR = File.join(File.dirname(__FILE__), "fixtures")

  def stub_configuration
    Nesta::Configuration.stub!(:configuration).and_return({
      "blog" => { "title" => "My blog", "subheading" => "about stuff" },
      "content" => File.join(File.dirname(__FILE__), ["fixtures"])
    })
  end

  def create_article(options = {})
    create_fixtures_directory
    metadata = { "Date" => "29 December 2008" }
    o = {
      :permalink => "my-article",
      :title => "My article",
      :metadata => metadata,
      :content => "Content goes here"
    }.merge(options)
    metatext = o[:metadata].map { |key, value| "#{key}: #{value}" }.join("\n")
    metatext += "\n\n" unless metatext.empty?
    contents =<<-EOF
#{metatext}# #{o[:title]}

#{o[:content]}
    EOF

    File.open(File.join(FIXTURE_DIR, "#{o[:permalink]}.mdown"), "w") do |f|
      f.write(contents)
    end
  end
  
  def remove_fixtures
    FileUtils.rm_r(FIXTURE_DIR, :force => true)
  end
  
  private
    def create_fixtures_directory
      FileUtils.mkdir_p(FIXTURE_DIR)
    end
end
