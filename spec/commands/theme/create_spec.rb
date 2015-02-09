require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require File.expand_path('../../../lib/nesta/commands', File.dirname(__FILE__))

describe "nesta:theme:create" do
  include_context "temporary working directory"

  def should_exist(file)
    File.exist?(Nesta::Path.themes(@name, file)).should be_true
  end

  before(:each) do
    Nesta::App.stub(:root).and_return(TempFileHelper::TEMP_DIR)
    @name = 'my-new-theme'
    Nesta::Commands::Theme::Create.new(@name).execute
  end

  it "should create the theme directory" do
    File.directory?(Nesta::Path.themes(@name)).should be_true
  end

  it "should create a dummy README file" do
    should_exist('README.md')
    text = File.read(Nesta::Path.themes(@name, 'README.md'))
    text.should match(/#{@name} is a theme/)
  end

  it "should create a default app.rb file" do
    should_exist('app.rb')
  end

  it "should create public and views directories" do
    should_exist("public/#{@name}")
    should_exist('views')
  end

  it "should copy the default view templates into views" do
    %w(layout.haml page.haml master.sass).each do |file|
      should_exist("views/#{file}")
    end
  end
end
