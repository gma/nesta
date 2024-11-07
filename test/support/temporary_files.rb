require 'fileutils'

module TemporaryFiles
  TEMP_DIR = File.expand_path('tmp', File.join(File.dirname(__FILE__), '..'))

  def remove_temp_directory
    if File.exist?(TemporaryFiles::TEMP_DIR)
      FileUtils.rm_r(TemporaryFiles::TEMP_DIR)
    end
  end

  def temp_path(base)
    File.join(TemporaryFiles::TEMP_DIR, base)
  end

  def project_root
    temp_path('mysite.com')
  end

  def project_path(path)
    File.join(project_root, path)
  end

  def in_temporary_project(*args, &block)
    FileUtils.mkdir_p(File.join(project_root, 'config'))
    FileUtils.touch(File.join(project_root, 'Gemfile'))
    FileUtils.touch(File.join(project_root, 'config', 'config.yml'))
    Dir.chdir(project_root) { yield project_root }
  ensure
    remove_temp_directory
  end

  def assert_exists_in_project(path)
    assert File.exist?(project_path(path)), "#{path} should exist"
  end
end
