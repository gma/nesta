module Nesta
  class SystemCommand
    def run(*args)
      system(*args)
      if ! $?.success?
        message = if $?.exitstatus == 127
                    "#{args[0]} not found"
                  else
                    "'#{args.join(' ')}' failed with status #{$?.exitstatus}"
                  end
        Nesta.fail_with(message)
      end
    end
  end
end
