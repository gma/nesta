require 'test_helper'

require_relative '../../../lib/nesta/static/assets'

describe 'Assets' do
  include TestConfiguration

  after do
    remove_temp_directory
  end

  it 'is happy if attachments directory not present' do
    in_temporary_project do |project_root|
      stub_config('content' => File.join(project_root, 'content')) do
        Nesta::Static::Assets.new('dist').copy_attachments
      end
    end
  end

  it 'copies attachments into build directory' do
    build_dir = 'dist'
    attachment = 'image.jpeg'

    in_temporary_project do |project_root|
      stub_config('content' => File.join(project_root, 'content')) do
        FileUtils.mkdir_p(Nesta::Config.attachment_path)
        open(File.join(Nesta::Config.attachment_path, attachment), 'w')

        Nesta::Static::Assets.new(build_dir).copy_attachments

        assert_exists_in_project File.join(build_dir, 'attachments', attachment)
      end
    end
  end

  it 'is happy if public directory not present' do
    in_temporary_project do |project_root|
      Nesta::Static::Assets.new('dist').copy_public_folder
    end
  end

  it 'copies contents of public directory into build directory' do
    build_dir = 'dist'
    asset_path = File.join('css', 'third-party.css')

    in_temporary_project do |project_root|
      public_path = File.join(project_root, 'public')
      FileUtils.mkdir_p(File.dirname(File.join(public_path, asset_path)))
      open(File.join(public_path, asset_path), 'w')

      Nesta::Static::Assets.new(build_dir).copy_public_folder

      assert_exists_in_project File.join(build_dir, asset_path)
    end
  end
end
