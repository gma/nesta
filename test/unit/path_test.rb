require 'test_helper'

describe Nesta::Path do
  def root
    '/path/to/site/on/filesystem'
  end

  describe '.local' do
    it 'returns root path of site on filesystem' do
      with_app_root(root) do
        assert_equal root, Nesta::Path.local
      end
    end

    it "should return path for file within site's directory" do
      with_app_root(root) do
        assert_equal "#{root}/foo/bar", Nesta::Path.local('foo/bar')
      end
    end

    it 'should combine path components' do
      with_app_root(root) do
        assert_equal "#{root}/foo/bar", Nesta::Path.local('foo', 'bar')
      end
    end
  end

  describe '.themes' do
    it 'should return themes path' do
      with_app_root(root) do
        assert_equal "#{root}/themes", Nesta::Path.themes
      end
    end

    it 'should return path for file within themes directory' do
      with_app_root(root) do
        assert_equal "#{root}/themes/foo/bar", Nesta::Path.themes('foo/bar')
      end
    end
  end
end
