require 'erb'
require 'fileutils'

require File.expand_path('env', File.dirname(__FILE__))
require File.expand_path('app', File.dirname(__FILE__))
require File.expand_path('path', File.dirname(__FILE__))
require File.expand_path('system_command', File.dirname(__FILE__))
require File.expand_path('version', File.dirname(__FILE__))

require File.expand_path('commands/build', File.dirname(__FILE__))
require File.expand_path('commands/demo', File.dirname(__FILE__))
require File.expand_path('commands/edit', File.dirname(__FILE__))
require File.expand_path('commands/new', File.dirname(__FILE__))
require File.expand_path('commands/plugin', File.dirname(__FILE__))
require File.expand_path('commands/template', File.dirname(__FILE__))
require File.expand_path('commands/theme', File.dirname(__FILE__))

module Nesta
  module Commands
    class UsageError < RuntimeError; end
  end
end
