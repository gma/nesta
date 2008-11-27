require "rubygems"

desc "Run the specs."
task :spec do
  Dir.new("spec").each do |filename|
    require File.join("spec", filename) if filename =~ /_spec.rb$/
  end
end
