require 'test_helper'

describe Nesta::Menu do
  include ModelFactory
  include TestConfiguration

  def with_page(&block)
    with_temp_content_directory do
      page = create(:page)
      create_menu(page.path)
      yield(page)
    end
  end

  def with_hierarchy_of_pages(&block)
    with_temp_content_directory do
      pages = (1..6).map { |i| create(:page) }
      text = <<-EOF
#{pages[0].path}
  #{pages[1].path}
    #{pages[2].path}
    #{pages[3].path}
    "no-such-page"
"another-missing-page"
#{pages[4].path}
  #{pages[5].path}
      EOF
      create_menu(text)
      yield(pages)
    end
  end

  after do
    remove_temp_directory
    Nesta::FileModel.purge_cache
  end

  it 'retrieves Page objects for the menu' do
    with_page do |page|
      assert_equal [page], Nesta::Menu.full_menu
      assert_equal [page], Nesta::Menu.for_path('/')
    end
  end

  it "filters pages that don't exist out of the menu" do
    with_temp_content_directory do
      page = create(:page)
      text = ['no-such-page', page.path].join("\n")
      create_menu(text)
      assert_equal [page], Nesta::Menu.top_level
    end
  end

  describe 'nested sub menus' do
    it 'returns top level menu items' do
      with_hierarchy_of_pages do |pages|
        assert_equal [pages[0], pages[4]], Nesta::Menu.top_level
      end
    end

    it 'returns full tree of menu items' do
      with_hierarchy_of_pages do |pages|
        page1, page2, page3, page4, page5, page6 = pages
        expected = [page1, [page2, [page3, page4]], page5, [page6]]
        assert_equal expected, Nesta::Menu.full_menu
      end
    end

    it 'returns part of the tree of menu items' do
      with_hierarchy_of_pages do |pages|
        page1, page2, page3, page4, page5, page6 = pages
        assert_equal [page2, [page3, page4]], Nesta::Menu.for_path(page2.path)
      end
    end

    it 'deems menu for path not in menu to be nil' do
      with_hierarchy_of_pages do
        assert_nil Nesta::Menu.for_path('wibble')
      end
    end
  end
end
