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

    # Define new actions (or override existing ones) here.
    # get '/hello' do
    #   'Hello!'
    # end
  end
end
