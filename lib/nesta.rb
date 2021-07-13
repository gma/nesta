module Nesta
  def self.deprecated(name, message)
    if Nesta::App.environment != :test
      $stderr.puts "DEPRECATION WARNING: #{name} is deprecated; #{message}"
    end
  end
end

require File.expand_path('nesta/plugin', File.dirname(__FILE__))
