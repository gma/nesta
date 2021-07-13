require 'test_helper'
require_relative '../../lib/nesta/process'

describe 'Nesta::Process' do
  describe '#run' do
    it 'catches errors when running external processes' do
      process = Nesta::Process.new
      process.run('ls / >/dev/null')
      begin
        stderr, $stderr = $stderr, File.open('/dev/null', 'w')
        assert_raises(SystemExit) do
          process.run('ls no-such-file 2>/dev/null')
        end
      ensure
        $stderr.close
        $stderr = stderr
      end
    end
  end
end
