require File.join(File.dirname(__FILE__), "config_spec_helpers")
require File.join(File.dirname(__FILE__), "spec_helper")

describe "Config" do
  include ConfigSpecHelper

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
      stub_config_key("content", "general/path")
      stub_env_config_key("content", "rack_env/path")
      Nesta::Config.content.should == "rack_env/path"
    end
  end
end
