require 'test_helper'

describe Nesta::Config do
  include TestConfiguration

  it 'defines default value for "Read more"' do
    assert_equal 'Continue reading', Nesta::Config.read_more
  end

  it 'returns nil for author when not defined' do
    assert_nil Nesta::Config.author
  end

  it 'reads configuration from YAML' do
    title = 'Site Title'
    stub_config('subtitle' => title) do
      assert_equal title, Nesta::Config.subtitle
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

  describe 'Nesta::Config.fetch' do
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
  end
end
