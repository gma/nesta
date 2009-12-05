require File.join(File.dirname(__FILE__), "model_factory")
require File.join(File.dirname(__FILE__), "spec_helper")

describe "Rendering" do
  include ModelFactory
  include RequestSpecHelper

  def create_template(type, name, content)
    views = File.join(@paths[type], "views")
    FileUtils.mkdir_p(views)
    open(File.join(views, name), "w") do |file|
      file.write(content)
    end
  end
  
  setup do
    Nesta::Path.local = File.join(File.dirname(__FILE__), *%w[.. test-local])
    @paths = {
      :local => Nesta::Path.local
    }
    stub_configuration
  end
  
  teardown do
    @paths.each_pair { |type, path| FileUtils.rm_rf(path) if File.exist?(path) }
  end
  
  describe "when local template exists" do
    setup do
      create_template(:local, "page.haml", "%p Local template")
      @category = create_category
    end
  
    it "should override default" do
      get @category.abspath
      body.should have_tag("p", "Local template")
    end
  end
end
