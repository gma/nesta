require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('model_factory', File.dirname(__FILE__))

describe "Rendering" do
  include ConfigSpecHelper
  include ModelFactory
  include RequestSpecHelper

  def create_fixture(type, name, content)
    base_path = {
      :local => Nesta::Path.local,
      :theme => Nesta::Path.themes(@theme)
    }[type]
    path = File.join(base_path, name)
    @fixtures << path
    FileUtils.mkdir_p(File.dirname(path))
    open(path, 'w') { |file| file.write(content) }
  end

  def create_template(type, name, content)
    create_fixture(type, File.join('views', 'layout.haml'), '= yield')
    create_fixture(type, File.join('views', name), content)
  end
  
  def create_app_file(type)
    create_fixture(type, 'app.rb', "DEFINED_IN_#{type.to_s.upcase}_FILE = true")
  end

  before(:each) do
    @app_root = Nesta::Env.root
    Nesta::Env.root = File.expand_path('fixtures/tmp', File.dirname(__FILE__))
    @theme = 'my-theme'
    @fixtures = []
    stub_configuration
  end
  
  after(:each) do
    @fixtures.each { |path| FileUtils.rm(path) if File.exist?(path) }
    Nesta::Env.root = @app_root
  end
    
  describe "when rendering stylesheets" do
    it "should render the SASS stylesheets" do
      create_template(:local, 'master.sass', "body\n  width: 10px * 2")
      get "/css/master.css"
      body.should match(/width: 20px;/)
    end

    it "should render the SCSS stylesheets" do
      create_template(:local, 'master.scss', "body {\n  width: 10px * 2;\n}")
      get "/css/master.css"
      body.should match(/width: 20px;/)
    end
  end

  describe "when local files exist" do
    before(:each) do
      create_template(:local, 'page.haml', '%p Local template')
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
      create_template(:theme, 'page.haml', '%p Theme template')
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
