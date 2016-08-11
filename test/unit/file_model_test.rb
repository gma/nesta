require 'test_helper'

describe Nesta::FileModel do
  include ModelFactory
  include TestConfiguration

  after do
    Nesta::FileModel.purge_cache
    remove_temp_directory
  end

  it 'can find all files of this type' do
    with_temp_content_directory do
      model = create(:file_model)
      assert_equal [model], Nesta::FileModel.find_all
    end
  end

  describe '.find_file_for_path' do
    it 'returns filename for path' do
      with_temp_content_directory do
        model = create(:file_model)
        filename = Nesta::FileModel.find_file_for_path(model.path)
        assert_equal filename, model.filename
      end
    end

    it 'returns nil if file not found' do
      with_temp_content_directory do
        assert_nil Nesta::FileModel.find_file_for_path('foobar')
      end
    end
  end

  it 'can parse metadata at top of a file' do
    with_temp_content_directory do
      model = create(:file_model)
      metadata = model.parse_metadata('My key: some value')
      assert_equal 'some value', metadata['my key']
    end
  end

  it "doesn't break loading pages with badly formatted metadata" do
    with_temp_content_directory do
      dodgy_metadata = "Key: value\nKey without value\nAnother key: value"
      page = create(:page) do |path|
        text = File.read(path)
        File.open(path, 'w') do |file|
          file.puts(dodgy_metadata)
          file.write(text)
        end
      end
      Nesta::Page.find_by_path(page.path)
    end
  end

  it 'invalidates cached models when files are modified' do
    with_temp_content_directory do
      create(:file_model, path: 'a-page', metadata: { 'Version' => '1' })
      now = Time.now
      File.stub(:mtime, now - 1) do
        Nesta::FileModel.load('a-page')
      end
      create(:file_model, path: 'a-page', metadata: { 'Version' => '2' })
      model = File.stub(:mtime, now) do
        Nesta::FileModel.load('a-page')
      end
      assert_equal '2', model.metadata('version')
    end
  end
end
