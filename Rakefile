require "rubygems"

desc "Run the tests."
task :test do
  begin; require "redgreen"; rescue LoadError; end
  Dir.new("test").each do |filename|
    require File.join("test", filename) if filename =~ /_test.rb$/
  end
end
