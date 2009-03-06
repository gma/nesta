require File.join(File.dirname(__FILE__), "spec_helper")

describe "Nesta::Configuration" do
  it "should have default category prefix" do
    Nesta::Configuration.category_prefix.should == ""
  end

  it "should have default article prefix" do
    Nesta::Configuration.article_prefix.should == "/articles"
  end
end