require "rubygems"
require "bundler/setup"

Bundler.require(:default, :test)

require "spec/rake/spectask"
Bundler::GemHelper.install_tasks

begin
  require "vlad"
  Vlad.load(:scm => :git, :app => nil, :web => nil)
rescue LoadError
end

require File.expand_path("lib/nesta/models", File.dirname(__FILE__))
require File.expand_path("lib/nesta/config", File.dirname(__FILE__))

desc "Run all specs in spec directory"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList["spec/*_spec.rb"]
end

namespace :heroku do
  desc "Set Heroku config vars from config.yml"
  task :config do
    Nesta::App.environment = ENV['RACK_ENV'] || 'production'
    settings = {}
    Nesta::Config.settings.map do |variable|
      value = Nesta::Config.send(variable)
      settings["NESTA_#{variable.upcase}"] = value unless value.nil?
    end
    if Nesta::Config.author
      %w[name uri email].map do |author_var|
        value = Nesta::Config.author[author_var]
        settings["NESTA_AUTHOR__#{author_var.upcase}"] = value unless value.nil?
      end
    end
    params = settings.map { |k, v| %Q{#{k}="#{v}"} }.join(" ")
    system("heroku config:add #{params}")
  end
end
