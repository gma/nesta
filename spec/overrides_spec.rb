require File.join(File.dirname(__FILE__), "model_factory")
require File.join(File.dirname(__FILE__), "spec_helper")

describe "Rendering" do
  include ModelFactory
  include RequestSpecHelper

  def create_fixture(type, name, content)
    path = File.join(@paths[type], name)
    @fixtures << path
    FileUtils.mkdir_p(File.dirname(path))
    open(path, "w") { |file| file.write(content) }
  end

  def create_template(type, name, content)
    create_fixture(type, File.join("views", name), content)
  end
  
  def create_app_file(type)
    create_fixture(type, "app.rb", "DEFINED_IN_#{type.to_s.upcase}_FILE = true")
  end

  before(:each) do
    Nesta::Path.local = File.join("test-local")
    Nesta::Path.themes = File.join("test-themes")
    @theme = "my-theme"
    @paths = {
      :local => Nesta::Path.local,
      :theme => File.join(Nesta::Path.themes, @theme)
    }
    @fixtures = []
    stub_configuration
  end
  
  after(:each) do
    @fixtures.each { |path| FileUtils.rm(path) if File.exist?(path) }
  end
    
  describe "when local files exist" do
    before(:each) do
      create_template(:local, "page.haml", "%p Local template")
    end
    
    it "should use local application files" do
      create_app_file(:local)
      Nesta::Overrides.load_local_app
      Object.const_get(:DEFINED_IN_LOCAL_FILE).should be_true
    end
  
    it "should use local template in place of default" do
      get create_category.abspath
      body.should have_tag("p", "Local template")
    end
  end
  
  describe "when theme installed" do
    before(:each) do
      create_template(:theme, "page.haml", "%p Theme template")
    end
    
    it "should not require theme application file automatically" do
      create_app_file(:theme)
      lambda {
        Object.const_get(:DEFINED_IN_THEME_FILE)
      }.should raise_error(NameError)
    end
  
    it "should not use theme templates automatically" do
      get create_category.abspath
      body.should_not have_tag("p", "Theme template")
    end
    
    describe "and configured" do
      before(:each) do
        stub_config_key("theme", @theme)
      end
      
      it "should require theme application file" do
        create_app_file(:theme)
        Nesta::Overrides.load_theme_app
        Object.const_get(:DEFINED_IN_THEME_FILE).should be_true
      end
      
      it "should use theme's template in place of default" do
        get create_category.abspath
        body.should have_tag("p", "Theme template")
      end
      
      context "and local files exist" do
        before(:each) do
          create_template(:local, "page.haml", "%p Local template")
        end
        
        it "should require local and theme application files" do
          create_app_file(:local)
          create_app_file(:theme)
          Nesta::Overrides.load_theme_app
          Nesta::Overrides.load_local_app
          Object.const_get(:DEFINED_IN_LOCAL_FILE).should be_true
          Object.const_get(:DEFINED_IN_THEME_FILE).should be_true
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
