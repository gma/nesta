# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'ctags-bundler' do
  watch(%r{^(app|lib|spec/support)/.*\.rb$})  { ["app", "lib", "spec/support"] }
  watch('Gemfile.lock')
end
