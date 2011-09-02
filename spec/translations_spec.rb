require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('model_factory', File.dirname(__FILE__))

describe "Page with multiple translations" do
  include ConfigSpecHelper
  include ModelFactory

  before(:each) do
    stub_configuration
    @current_app = Object.new
    Nesta::App.stub(:current_app).and_return(@current_app)
    stub_locale("en")
  end

  after(:each) do
    remove_fixtures
    Nesta::FileModel.purge_cache
  end

  def stub_locale(code)
    @current_app.stub(:current_locale).and_return(code)
  end

  it "should respond to different locales" do
    create_page(:path => 'carrots',
                :translations => {
                  :en => {:heading => 'Carrot', :content =>'Carrots are good for you'},
                  :pt => {:heading => 'Cenoura', :content =>'Cenouras fazem bem'}})
    @page = Nesta::Page.find_by_path('carrots')
    stub_locale("en")
    @page.heading.should == 'Carrot'
    stub_locale("pt")
    @page.heading.should == 'Cenoura'
  end

  it "should respect language-specific metadata" do
    create_page(:path => 'carrots',
                :translations => {
                  :en => {
                    :heading => 'Carrot',
                    :content =>'Carrots are good for you',
                    :metadata => {
                      :somekey => 'something',
                      :poet => 'Shakespeare'
                      
                    }},
                  :pt => {
                    :heading => 'Cenoura',
                    :content =>'Cenouras fazem bem',
                    :metadata => {
                      :somekey => 'alguma coisa',
                      :poeta => 'Pessoa'
                    }}
                })
    @page = Nesta::Page.find_by_path('carrots')
    stub_locale('en')
    @page.metadata('somekey').should == 'something'
    @page.metadata('poet').should == 'Shakespeare'
    @page.metadata('poeta').should be_nil
    stub_locale('pt')
    @page.metadata('somekey').should == 'alguma coisa'
    @page.metadata('poet').should be_nil
    @page.metadata('poeta').should == 'Pessoa'
  end
  
end
