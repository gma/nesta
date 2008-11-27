require File.join(File.dirname(__FILE__), "spec_helper")
require "mocha"

describe "home page" do
  before(:each) do
    Nesta::Configuration.stubs(:configuration).returns({
      "blog" => { "title" => "My blog", "subheading" => "about stuff" }
    })
  end
  
  it "should display site title" do
    get_it "/"
    should.be.ok
    @response.body.should.match "My blog"
  end
end
