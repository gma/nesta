require "rubygems"
require "sinatra"
require "sinatra/test/spec"

begin
  require "redgreen"
rescue LoadError
end

NESTA_ROOT = File.join(File.dirname(__FILE__), "..")

set_options :views => File.join(NESTA_ROOT, "views"),
            :public => File.join(NESTA_ROOT, "public")

require File.join(NESTA_ROOT, "nesta")
