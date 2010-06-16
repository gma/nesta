module ConfigSpecHelper

  FIXTURE_DIR = File.join(File.dirname(__FILE__), "fixtures")

  def initialise_config
    @config = {}
    Nesta::Config.stub!(:yaml_conf).and_return(@config)
  end

  def stub_config_key(key, value)
    initialise_config if @config.nil?
    @config[key] = value
  end
  
  def stub_env_config_key(key, value)
    initialise_config if @config.nil?
    @config["test"] ||= {}
    @config["test"][key] = value
  end
  
  def stub_configuration
    stub_config_key("title", "My blog")
    stub_config_key("subtitle", "about stuff")
    stub_config_key("description", "great web site")
    stub_config_key("keywords", "home, page")
    stub_env_config_key("content", ConfigSpecHelper::FIXTURE_DIR)
  end
end
