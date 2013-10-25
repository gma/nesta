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
      Nesta::Config.settings << 'a_boolean'
      begin
        ENV["NESTA_A_BOOLEAN"] = "true"
        Nesta::Config.a_boolean.should be_true
        ENV["NESTA_A_BOOLEAN"] = "false"
        Nesta::Config.a_boolean.should be_false
      ensure
        Nesta::Config.settings.pop
        ENV.delete('NESTA_A_BOOLEAN')
      end
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

  describe 'user defined config variables' do
    it 'should be retrieved from ENV' do
      ENV['NESTA_MY_SETTING'] = 'value in ENV'
      begin
        Nesta::Config.fetch('my_setting').should == 'value in ENV'
        Nesta::Config.fetch(:my_setting).should == 'value in ENV'
      ensure
        ENV.delete('NESTA_MY_SETTING')
      end
    end

    it 'should be retrieved from YAML' do
      stub_config_key('my_setting', 'value in YAML')
      Nesta::Config.fetch('my_setting').should == 'value in YAML'
      Nesta::Config.fetch(:my_setting).should == 'value in YAML'
    end

    it "should throw an error when retrieved if they don't exist" do
      lambda {
        Nesta::Config.fetch('who me?')
      }.should raise_error(Nesta::Config::NotDefined)
    end
  end
end
