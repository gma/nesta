module Nesta
  class Process
    def run(*args)
      system(*args)
      if ! $?.success?
        message = if $?.exitstatus == 127
                    "#{args[0]} not found"
                  else
                    "'#{args.join(' ')}' failed with status #{$?.exitstatus}"
                  end
        fail(message)
      end
    end

    def fail(message)
      $stderr.puts "Error: #{message}"
      exit 1
    end
  end
end
