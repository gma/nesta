require 'test_helper'
require_relative '../../lib/nesta/system_command'

describe 'Nesta::SystemCommand' do
  describe '#run' do
    it 'catches errors when running external processes' do
      command = Nesta::SystemCommand.new
      command.run('ls / >/dev/null')
      begin
        stderr, $stderr = $stderr, File.open('/dev/null', 'w')
        assert_raises(SystemExit) do
          command.run('ls no-such-file 2>/dev/null')
        end
      ensure
        $stderr.close
        $stderr = stderr
      end
    end
  end
end
