module Nesta
  class App
    helpers do
      def gist(gn)
        "<script type='text/javascript' src='https://gist.github.com/#{gn}.js'></script>"
      end
    end

    # Define new actions (or override existing ones) here.
    # get '/hello' do
    #   'Hello!'
    # end
  end
end
