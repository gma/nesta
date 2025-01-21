require 'test_helper'

require_relative '../../../lib/nesta/static/site'

describe 'Site' do
  include ModelFactory
  include TestConfiguration

  after do
    remove_temp_directory
  end

  it 'converts Markdown to HTML' do
    build_dir = 'dist'
    domain = 'localhost'

    in_temporary_project do
      with_temp_content_directory do
        page = create(:page)

        Nesta::Static::Site.new(build_dir, domain).render_pages

        html_file = File.join(build_dir, page.abspath + '.html')
        markup = open(html_file).read

        assert markup.include?("<title>#{page.title}</title>")
      end
    end
  end

  it 'renders a 404 not found page' do
    build_dir = 'dist'
    domain = 'localhost'

    in_temporary_project do
      with_temp_content_directory do
        Nesta::Static::Site.new(build_dir, domain).render_not_found

        html_file = File.join(build_dir, '404.html')
        markup = open(html_file).read

        assert markup.include?("<h1>Page not found</h1>")
      end
    end
  end

  it 'renders Atom feed' do
    build_dir = 'dist'
    domain = 'mysite.com'

    in_temporary_project do
      with_temp_content_directory do
        article = create(:article)
        Nesta::Static::Site.new(build_dir, domain).render_atom_feed

        xml_file = File.join(build_dir, 'articles.xml')
        xml = open(xml_file).read

        assert xml.include?("<link href='https://#{domain + article.abspath}'")
      end
    end
  end

  it 'includes domain name in sitemap' do
    build_dir = 'dist'
    domain = 'mysite.com'

    in_temporary_project do
      with_temp_content_directory do
        page = create(:page)
        Nesta::Static::Site.new(build_dir, domain).render_sitemap

        xml_file = File.join(build_dir, 'sitemap.xml')
        xml = open(xml_file).read

        assert xml.include?(domain + page.abspath)
      end
    end
  end

  it "renders the user's list of templated assets" do
    build_dir = 'dist'
    css_path = '/css/styles.css'

    in_temporary_project do
      stub_config('build' => { 'templated_assets' => [css_path] }) do
        views = File.join(project_root, 'views')
        FileUtils.mkdir_p(views)
        open(File.join(views, 'styles.sass'), 'w') do |sass|
          sass.write("p\n  font-size: 1em\n")
        end

        site = Nesta::Static::Site.new(build_dir, 'mysite.com')
        site.render_templated_assets

        css_file = File.join(build_dir, css_path)
        assert_exists_in_project(css_file)

        assert_equal open(css_file).read, "p {\n  font-size: 1em;\n}"
      end
    end
  end
end
