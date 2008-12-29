require "rubygems"

desc "Run the specs."
task :spec do
  Dir.new("spec").each do |filename|
    require File.join("spec", filename) if filename =~ /_spec.rb$/
  end
end

namespace :db do
  desc "Auto-migrate the database."
  task :migrate do
    require File.join(File.dirname(__FILE__), *%w[lib models])
    DataMapper.auto_migrate!
  end
end