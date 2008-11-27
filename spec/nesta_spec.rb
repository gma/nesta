require File.join(File.dirname(__FILE__), "spec_helper")
require "mocha"

describe "home page" do
  before(:each) do
    Nesta::Configuration.stubs(:configuration).returns({
      "blog" => { "title" => "My blog", "subheading" => "about stuff" }
    })
    get_it "/"
  end

  it "should render successfully" do
    should.be.ok
  end
  
  it "should display title in title tag" do
    @response.body.should.match "<title>My blog</title>"
  end
  
  it "should display site title in h1 tag" do
    @response.body.should.match %r{<h1>\s*<a href='/'>My blog}
  end
  
  it "should display site subheading in h1 tag" do
    @response.body.should.match %r{about stuff\s*</small>\s*</h1}
  end
end
