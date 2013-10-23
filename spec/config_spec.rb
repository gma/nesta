require File.expand_path('spec_helper', File.dirname(__FILE__))

describe "Config" do
  after(:each) do
    ENV.keys.each { |variable| ENV.delete(variable) if variable =~ /NESTA_/ }
  end
  
  describe "when settings defined in ENV" do
    before(:each) do
      @title = "Title from ENV"
      ENV["NESTA_TITLE"] = @title
    end
    
    it "should never try and access config.yml" do
      stub_config_key("subtitle", "Subtitle in YAML file")
      Nesta::Config.subtitle.should be_nil
    end

    it "should override config.yml" do
      stub_config_key("title", "Title in YAML file")
      Nesta::Config.title.should == @title
    end
    
    it "should know how to cope with boolean values" do
      ENV["NESTA_CACHE"] = "true"
      Nesta::Config.cache.should be_true
      ENV["NESTA_CACHE"] = "false"
      Nesta::Config.cache.should be_false
    end
    
    it "should set author hash from ENV" do
      name = "Name from ENV"
      uri = "URI from ENV"
      ENV["NESTA_AUTHOR__NAME"] = name
      ENV["NESTA_AUTHOR__URI"] = uri
      Nesta::Config.author["name"].should == name
      Nesta::Config.author["uri"].should == uri
      Nesta::Config.author["email"].should be_nil
    end
  end
  
  describe "when settings only defined in config.yml" do
    before(:each) do
      @title = "Title in YAML file"
      stub_config_key("subtitle", @title)
    end
    
    it "should read configuration from YAML" do
      Nesta::Config.subtitle.should == @title
    end

    it "should set author hash from YAML" do
      name = "Name from YAML"
      uri = "URI from YAML"
      stub_config_key("author", { "name" => name, "uri" => uri })
      Nesta::Config.author["name"].should == name
      Nesta::Config.author["uri"].should == uri
      Nesta::Config.author["email"].should be_nil
    end
    
    it "should override top level settings with RACK_ENV specific settings" do
      stub_config_key('content', 'general/path')
      stub_config_key('content', 'rack_env/path', :rack_env => true)
      Nesta::Config.content.should == 'rack_env/path'
    end
  end

  it "should prepend the project path to content path if the content path is relative" do
    Nesta::App.stub!(:root).and_return("/project/path")
    stub_config_key('content', 'relative/path')
    Nesta::Config.content_path.should == "/project/path/relative/path"
  end

  it "should not prepend the project path to content path if the content path is absolute" do
    Nesta::App.stub!(:root).and_return("/project/path")
    stub_config_key('content', '/absolute/path')
    Nesta::Config.content_path.should == "/absolute/path"
  end
end
