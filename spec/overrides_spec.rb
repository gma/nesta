require File.join(File.dirname(__FILE__), "model_factory")
require File.join(File.dirname(__FILE__), "spec_helper")

describe "Rendering" do
  include ModelFactory
  include RequestSpecHelper

  def create_template(type, name, content)
    template = File.join(@paths[type], "views", name)
    FileUtils.mkdir_p(File.dirname(template))
    open(template, "w") { |file| file.write(content) }
    @templates << template
  end
  
  setup do
    Nesta::Path.local = File.join(File.dirname(__FILE__), *%w[.. test-local])
    Nesta::Path.themes = File.join(File.dirname(__FILE__), *%w[.. test-themes])
    @theme = "my-theme"
    @paths = {
      :local => Nesta::Path.local,
      :theme => File.join(Nesta::Path.themes, @theme)
    }
    @templates = []
    stub_configuration
  end
  
  teardown do
    @templates.each { |path| FileUtils.rm(path) if File.exist?(path) }
  end
  
  describe "when local template exists" do
    setup do
      create_template(:local, "page.haml", "%p Local template")
    end
  
    it "should override default" do
      get create_category.abspath
      body.should have_tag("p", "Local template")
    end
  end
  
  describe "when template exists in theme" do
    setup do
      create_template(:theme, "page.haml", "%p Theme template")
    end
    
    it "should not be used automatically" do
      get create_category.abspath
      body.should_not have_tag("p", "Theme template")
    end
    
    describe "and theme configured" do
      setup do
        stub_config_key("theme", @theme)
      end
      
      it "should override the default" do
        get create_category.abspath
        body.should have_tag("p", "Theme template")
      end
      
      context "and template also exists locally" do
        setup do
          create_template(:local, "page.haml", "%p Local template")
        end

        it "should use local template" do
          get create_category.abspath
          body.should_not have_tag("p", "Theme template")
          body.should have_tag("p", "Local template")
        end
      end
    end
  end
end
