module Nesta
  class App
    use Rack::Static, :urls => ["/postal3"], :root => "themes/postal3/public"
  end
end
