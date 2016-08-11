require 'test_helper'

describe Nesta::Config do
  include TestConfiguration

  after do
    ENV.keys.each { |variable| ENV.delete(variable) if variable =~ /NESTA_/ }
  end

  it 'returns default value for "Read more"' do
    assert_equal 'Continue reading', Nesta::Config.read_more
  end

  it 'returns nil for author when not defined' do
    assert_equal nil, Nesta::Config.author
  end

  describe 'when settings defined in ENV' do
    before do
      @title = 'Title from ENV'
      ENV['NESTA_TITLE'] = @title
    end

    it 'falls back to config.yml' do
      stub_config('subtitle' => 'Subtitle in YAML file') do
        assert_equal 'Subtitle in YAML file', Nesta::Config.subtitle
      end
    end

    it 'overrides config.yml' do
      stub_config('title' => 'Title in YAML file') do
        assert_equal @title, Nesta::Config.title
      end
    end

    it 'knows how to cope with boolean values' do
      Nesta::Config.settings << 'a_boolean'
      begin
        ENV['NESTA_A_BOOLEAN'] = 'true'
        assert_equal true, Nesta::Config.a_boolean, 'should be true'
        ENV['NESTA_A_BOOLEAN'] = 'false'
        assert_equal false, Nesta::Config.a_boolean, 'should be false'
      ensure
        Nesta::Config.settings.pop
        ENV.delete('NESTA_A_BOOLEAN')
      end
    end

    it 'should return configured value for "Read more"' do
      ENV['NESTA_READ_MORE'] = 'Read on'
      begin
        assert_equal 'Read on', Nesta::Config.read_more
      ensure
        ENV.delete('NESTA_READ_MORE')
      end
    end

    it 'sets author hash from ENV' do
      name = 'Name from ENV'
      uri = 'URI from ENV'
      ENV['NESTA_AUTHOR__NAME'] = name
      ENV['NESTA_AUTHOR__URI'] = uri
      assert_equal name, Nesta::Config.author['name']
      assert_equal uri, Nesta::Config.author['uri']
      assert Nesta::Config.author['email'].nil?, 'should be nil'
    end
  end

  describe 'when settings only defined in config.yml' do
    before do
      @title = 'Title in YAML file'
    end

    it 'reads configuration from YAML' do
      stub_config('subtitle' => @title) do
        assert_equal @title, Nesta::Config.subtitle
      end
    end

    it 'sets author hash from YAML' do
      name = 'Name from YAML'
      uri = 'URI from YAML'
      stub_config('author' => { 'name' => name, 'uri' => uri }) do
        assert_equal name, Nesta::Config.author['name']
        assert_equal uri, Nesta::Config.author['uri']
        assert Nesta::Config.author['email'].nil?, 'should be nil'
      end
    end

    it 'overrides top level settings with environment specific settings' do
      config = {
        'content' => 'general/path',
        'test' => { 'content' => 'rack_env_specific/path' }
      }
      stub_config(config) do
        assert_equal 'rack_env_specific/path', Nesta::Config.content
      end
    end
  end

  describe 'Nesta::Config.fetch' do
    it 'retrieves settings from environment' do
      ENV['NESTA_MY_SETTING'] = 'value in ENV'
      begin
        assert_equal 'value in ENV', Nesta::Config.fetch('my_setting')
        assert_equal 'value in ENV', Nesta::Config.fetch(:my_setting)
      ensure
        ENV.delete('NESTA_MY_SETTING')
      end
    end

    it 'retrieves settings from YAML' do
      stub_config('my_setting' => 'value in YAML') do
        assert_equal 'value in YAML', Nesta::Config.fetch('my_setting')
        assert_equal 'value in YAML', Nesta::Config.fetch(:my_setting)
      end
    end

    it "throws NotDefined if a setting isn't defined" do
      assert_raises(Nesta::Config::NotDefined) do
        Nesta::Config.fetch('no such setting')
      end
    end

    it 'allows default values to be set' do
      assert_equal 'default', Nesta::Config.fetch('no such setting', 'default')
    end

    it 'copes with non-truthy boolean values' do
      ENV['NESTA_SETTING'] = 'false'
      begin
        assert_equal false, Nesta::Config.fetch('setting')
      ensure
        ENV.delete('NESTA_SETTING')
      end
    end
  end
end
