require 'test_helper'
require_relative '../../lib/nesta/commands'

class TestCommand
  include Nesta::Commands::Command
end

describe 'Nesta::Commands::Command' do
  describe '#run_process' do
    it 'catches errors when running external processes' do
      TestCommand.new.run_process('ls / >/dev/null')
      begin
        stderr, $stderr = $stderr, File.open('/dev/null', 'w')
        assert_raises(SystemExit) do
          TestCommand.new.run_process('ls no-such-file 2>/dev/null')
        end
      ensure
        $stderr.close
        $stderr = stderr
      end
    end
  end
end
