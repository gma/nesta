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
end
