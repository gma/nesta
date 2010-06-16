require File.join(File.dirname(__FILE__), "config_spec_helpers")
require File.join(File.dirname(__FILE__), "spec_helper")

describe "Config" do
  include ConfigSpecHelper

  after(:each) do
    ENV.keys.each { |variable| ENV.delete(variable) if variable =~ /NESTA_/ }
  end
  
  describe "when only defined in config.yml" do
    it "should read simple configuration from config.yml" do
      Nesta::Config.top_level_settings.each do |setting|
        stub_config_key(setting, "#{setting} in config.yml")
        Nesta::Config.send(setting).should == "#{setting} in config.yml"
      end
    end

    it "should read author config from config.yml" do
      @author_name = "Barry Chuckle"
      stub_config_key("author", { "name" => @author_name })
      Nesta::Config.author["name"].should == @author_name
      Nesta::Config.author["email"].should be_nil
    end
    
    it "should read environment specific config from config.yml" do
      stub_env_config_key("cache", true)
      Nesta::Config.cache.should be_true
    end
  end
  
  describe "when simple settings defined in ENV" do
    before(:each) do
      settings = Nesta::Config.top_level_settings + \
          Nesta::Config.per_environment_settings
      settings.each do |setting|
        variable = "NESTA_#{setting.upcase}"
        ENV[variable] = "#{setting} from ENV"
      end
    end
    
    it "should override config.yml" do
      assert ENV.keys.grep(/^NESTA_/).size > 0
      ENV.keys.grep(/^NESTA_/).each do |variable|
        method = variable.sub("NESTA_", "").downcase
        Nesta::Config.send(method).should == ENV[variable]
      end
    end
  end
  
  describe "when nested author settings defined in ENV" do
    before(:each) do
      @author_name = "Paul Chuckle"
      ENV["NESTA_AUTHOR__NAME"] = @author_name
    end
    
    it "should override author in config.yml" do
      Nesta::Config.author["name"].should == @author_name
      Nesta::Config.author["email"].should be_nil
      Nesta::Config.author["uri"].should be_nil
    end
  end
end
