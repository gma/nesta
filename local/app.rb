module Nesta
  class App
    helpers do
      def gist(gn,filename=nil)
        if(!filename.nil?)
          filename = "?file=#{filename}"
        end
        "<script type='text/javascript' src='https://gist.github.com/#{gn}.js#{filename}'></script>"
      end

      def link_to(url,text=nil)
          "<a href='#{url}'>#{text || url}</a>"
      end
    end

    get "/" do
      set_common_variables
      set_from_config(:title, :subtitle, :description, :keywords)
      @heading = @title
      @title = "#{@title} - #{@subtitle}"
      # paginate?
      @articles = Page.find_articles[0..20]
      @body_class = "home"
      cache haml(:index)
    end

    # Define new actions (or override existing ones) here.
    # get '/hello' do
    #   'Hello!'
    # end
  end
end
