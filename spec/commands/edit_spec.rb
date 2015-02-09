require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../lib/nesta/commands', File.dirname(__FILE__))

describe "nesta:edit" do
  include_context "temporary working directory"

  before(:each) do
    Nesta::Config.stub(:content_path).and_return('content')
    @page_path = 'path/to/page.mdown'
    @command = Nesta::Commands::Edit.new(@page_path)
    @command.stub(:run_process)
  end

  it "should launch the editor" do
    ENV['EDITOR'] = 'vi'
    full_path = File.join('content/pages', @page_path)
    @command.should_receive(:run_process).with(ENV['EDITOR'], full_path)
    @command.execute
  end

  it "should not try and launch an editor if environment not setup" do
    ENV.delete('EDITOR')
    @command.should_not_receive(:run_process)
    $stderr.stub(:puts)
    @command.execute
  end
end
