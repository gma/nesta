module TestConfiguration
  include TemporaryFiles

  def stub_config(config, &block)
    Nesta::Config.stub(:yaml_exists?, true) do
      Nesta::Config.stub(:yaml_conf, config) do
        yield
      end
    end
  end

  def temp_content
    { 'content' => temp_path('content') }
  end

  def with_temp_content_directory(&block)
    stub_config(temp_content) { yield }
  end
end
