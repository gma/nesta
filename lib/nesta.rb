module Nesta
  def self.deprecated(name, message)
    $stderr.puts "DEPRECATION WARNING: #{name} is deprecated; #{message}"
  end

  def self.fail_with(message)
    $stderr.puts "Error: #{message}"
    exit 1
  end
end

require File.expand_path('nesta/plugin', File.dirname(__FILE__))
