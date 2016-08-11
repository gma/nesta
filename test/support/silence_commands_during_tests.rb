module SilenceCommandsDuringTests
  def run_process(*args)
    super(*args, out: '/dev/null', err: '/dev/null')
  end
end
