require 'integration_test_helper'

describe 'Overriding files in gem and themes' do
  include Nesta::IntegrationTest

  def in_nesta_project(config = {}, &block)
    app_root = temp_path('root')
    content_config = { 'content' => File.join(app_root, 'content') }
    stub_config(content_config.merge(config)) do
      with_app_root(app_root) do
        block.call
      end
    end
  ensure
    remove_temp_directory
  end

  def theme_name
    'my-theme'
  end

  def create_fixture(type, name, content)
    base_path = {
      local: Nesta::Path.local,
      theme: Nesta::Path.themes(theme_name)
    }[type]
    path = File.join(base_path, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') { |file| file.write(content) }
  end

  def create_app_file(type)
    create_fixture(type, 'app.rb', "FROM_#{type.to_s.upcase} = true")
  end

  describe 'app.rb' do
    it 'loads app.rb from configured theme' do
      in_nesta_project('theme' => theme_name) do
        create_app_file(:theme)
        Nesta::Overrides.load_theme_app
        assert Object.const_get(:FROM_THEME), 'should load app.rb in theme'
      end
    end

    it 'loads both local and theme app.rb files' do
      in_nesta_project('theme' => theme_name) do
        create_app_file(:local)
        Nesta::Overrides.load_local_app
        create_app_file(:theme)
        Nesta::Overrides.load_theme_app
        assert Object.const_get(:FROM_THEME), 'should load app.rb in theme'
        assert Object.const_get(:FROM_LOCAL), 'should load local app.rb'
      end
    end
  end

  def create_view(type, name, content)
    create_fixture(type, File.join('views', name), content)
  end

  describe 'rendering stylesheets' do
    it 'renders Sass stylesheets' do
      in_nesta_project do
        create_view(:local, 'master.sass', "body\n  width: 10px * 2")
        visit '/css/master.css'
        assert_match /width: 20px;/, body, 'should match /width: 20px;/'
      end
    end

    it 'renders SCSS stylesheets' do
      in_nesta_project do
        create_view(:local, 'master.scss', "body {\n  width: 10px * 2;\n}")
        visit '/css/master.css'
        assert_match /width: 20px;/, body, 'should match /width: 20px;/'
      end
    end

    it 'renders stylesheet in the gem if no others found' do
      in_nesta_project do
        visit '/css/master.css'
        assert_equal 200, page.status_code
      end
    end
  end

  def create_haml(type, name, content)
    create_view(type, 'layout.haml', '= yield')
    create_view(type, name, content)
  end

  describe 'rendering Haml' do
    it 'uses local template in place of default' do
      in_nesta_project do
        create_haml(:local, 'page.haml', '%p Local template')
        visit create(:category).abspath
        assert_has_xpath '//p', text: 'Local template'
      end
    end

    it 'uses theme template in place of default' do
      in_nesta_project('theme' => theme_name) do
        create_haml(:theme, 'page.haml', '%p Theme template')
        visit create(:category).abspath
        assert_has_xpath '//p', text: 'Theme template'
      end
    end

    it 'prioritise local templates over theme templates' do
      in_nesta_project('theme' => theme_name) do
        create_haml(:local, 'page.haml', '%p Local template')
        create_haml(:theme, 'page.haml', '%p Theme template')
        visit create(:category).abspath
        assert_has_xpath '//p', text: 'Local template'
        assert_has_no_xpath '//p', text: 'Theme template'
      end
    end
  end
end
