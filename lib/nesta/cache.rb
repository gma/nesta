require 'fileutils'
# require 'sinatra/base'

module Sinatra 
    
  # Sinatra Caching module
  # 
  #  TODO:: Need to write documentation here 
  # 
  module Cache
    
    VERSION = 'Sinatra::Cache v0.2.0'
    def self.version; VERSION; end
    
    
    module Helpers 
      
      # Caches the given URI to a html file in /public
      # 
      # <b>Usage:</b>
      #    >> cache( erb(:contact, :layout => :layout))
      #      =>  returns the HTML output written to /public/<CACHE_DIR_PATH>/contact.html
      # 
      # Also accepts an Options Hash, with the following options:
      #  * :extension => in case you need to change the file extension
      #  
      #  TODO:: implement the opts={} hash functionality. What other options are needed?
      # 
      def cache(content, opts={})
        return content unless options.cache_enabled
        
        unless content.nil?
          content = "#{content}\n#{page_cached_timestamp}\n"
          path = cache_page_path(request.path_info,opts)
          FileUtils.makedirs(File.dirname(path))
          open(path, 'wb+') { |f| f << content }
          log("Cached Page: [#{path}]",:info) 
          content
        end
      end
      
      # Expires the cached URI (as .html file) in /public
      # 
      # <b>Usage:</b>
      #    >> cache_expire('/contact')
      #      =>  deletes the /public/<CACHE_DIR_PATH>contact.html page
      # 
      #    get '/contact' do 
      #     cache_expire   # deletes the /public/<CACHE_DIR_PATH>contact.html page as well
      #    end
      #
      #  TODO:: implement the options={} hash functionality. What options are really needed ? 
      def cache_expire(path = nil, opts={})
        return unless options.cache_enabled
        
        path = (path.nil?) ? cache_page_path(request.path_info) : cache_page_path(path)
        if File.exist?(path)
          File.delete(path)
          log("Expired Page deleted at: [#{path}]",:info)
        else
          log("No Expired Page was found at the path: [#{path}]",:info)
        end
      end
      
      # Prints a basic HTML comment with a timestamp in it, so that you can see when a file was cached last.
      # 
      # *NB!* IE6 does NOT like this to be the first line of a HTML document, so output
      # inside the <head> tag. Many hours wasted on that lesson ;-)
      # 
      # <b>Usage:</b>
      #    >> <%= page_cached_timestamp %>
      #      => <!--  page cached: 2009-02-24 12:00:00 -->
      #
      def page_cached_timestamp
        "<!-- page cached: #{Time.now.strftime("%Y-%d-%m %H:%M:%S")} -->\n" if options.cache_enabled
      end
      
      
      private
        
        # Establishes the file name of the cached file from the path given
        # 
        # TODO:: implement the opts={} functionality, and support for custom extensions on a per request basis. 
        # 
        def cache_file_name(path,opts={})
          name = (path.empty? || path == "/") ? "index" : Rack::Utils.unescape(path.sub(/^(\/)/,'').chomp('/'))
          name << options.cache_page_extension unless (name.split('/').last || name).include? '.'
          return name
        end
        
        # Sets the full path to the cached page/file
        # Dependent upon Sinatra.options .public and .cache_dir variables being present and set.
        # 
        def cache_page_path(path,opts={})
          # test if given a full path rather than relative path, otherwise join the public path to cache_dir 
          # and ensure it is a full path
          cache_dir = (options.cache_dir == File.expand_path(options.cache_dir)) ? 
              options.cache_dir : File.expand_path("#{options.public}/#{options.cache_dir}")
          cache_dir = cache_dir[0..-2] if cache_dir[-1,1] == '/'
          "#{cache_dir}/#{cache_file_name(path,opts)}"
        end
        
        #  TODO:: this implementation really stinks, how do I incorporate Sinatra's logger??
        def log(msg,scope=:debug)
          if options.cache_logging
            "Log: msg=[#{msg}]" if scope == options.cache_logging_level
          else
            # just ignore the stuff...
            # puts "just ignoring msg=[#{msg}] since cache_logging => [#{options.cache_logging.to_s}]"
          end
        end
        
    end #/module Helpers
    
    
    # Sets the default options:
    # 
    #  * +:cache_enabled+ => toggle for the cache functionality. Default is: +true+
    #  * +:cache_page_extension+ => sets the default extension for cached files. Default is: +.html+
    #  * +:cache_dir+ => sets cache directory where cached files are stored. Default is: ''(empty) == root of /public.<br>
    #      set to empty, since the ideal 'system/cache/' does not work with Passenger & mod_rewrite :(
    #  * +cache_logging+ => toggle for logging the cache calls. Default is: +true+
    #  * +cache_logging_level+ => sets the level of the cache logger. Default is: <tt>:info</tt>.<br>
    #      Options:(unused atm) [:info, :warn, :debug]
    # 
    def self.registered(app)
      app.helpers(Cache::Helpers)
      app.set :cache_enabled, true
      app.set :cache_page_extension, '.html'
      app.set :cache_dir, ''
      app.set :cache_logging, true
      app.set :cache_logging_level, :info
    end
    
  end #/module Cache
  
  register(Sinatra::Cache)
  
end #/module Sinatra