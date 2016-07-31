require "rubygems"
require "bundler/setup"

Bundler.require(:default, :test)

Bundler::GemHelper.install_tasks

namespace :test do
  task :set_load_path do
    $LOAD_PATH.unshift File.expand_path('test')
  end

  def load_tests(directory)
    Rake::FileList["test/#{directory}/*_test.rb"].each { |f| require_relative f }
  end

  task units: :set_load_path do
    load_tests('unit')
  end

  task integrations: :set_load_path do
    load_tests('integration')
  end
end

task test: 'test:set_load_path' do
  load_tests('**')
end
