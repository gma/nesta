module TestConfiguration
  include TemporaryFiles

  def stub_config(config, &block)
    Nesta::Config.instance.stub(:config, config) do
      block.call
    end
  end

  def temp_content
    { 'content' => temp_path('content') }
  end

  def with_temp_content_directory(&block)
    stub_config(temp_content) { block.call }
  end
end
