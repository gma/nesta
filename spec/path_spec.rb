require File.expand_path("spec_helper", File.dirname(__FILE__))

describe "Nesta::Path" do
  before(:each) do
    @root = File.expand_path('..', File.dirname(__FILE__))
    @local_foo_bar = File.join(@root, "local", "foo/bar")
  end

  it "should return local path" do
    Nesta::Path.local.should == File.expand_path("local", @root)
  end

  it "should return path for file within local directory" do
    Nesta::Path.local("foo/bar").should == @local_foo_bar
  end

  it "should combine path components" do
    Nesta::Path.local("foo", "bar").should == @local_foo_bar
  end

  it "should return themes path" do
    root = File.dirname(File.dirname(__FILE__))
    Nesta::Path.themes.should == File.expand_path("themes", @root)
  end

  it "should return path for file within themes directory" do
    Nesta::Path.themes("foo/bar").should == File.join(@root, "themes", "foo/bar")
  end
end
