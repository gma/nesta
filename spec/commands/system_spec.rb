require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../lib/nesta/commands', File.dirname(__FILE__))

class TestCommand
  include Nesta::Commands::Command
end

describe "Nesta::Commands::Command.run_process" do
  before do
    @stderr = $stderr
    $stderr = File.new('/dev/null', 'w')
  end

  after do
    $stderr.close
    $stderr = @stderr
  end

  it 'can run an external process and catch errors' do
    TestCommand.new.run_process('ls / >/dev/null')
    expect {
      TestCommand.new.run_process('ls /no-such-file 2>/dev/null')
    }.to raise_error(SystemExit)
  end
end
