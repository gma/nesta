# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)                                       
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)  
require "<%= @gem_name %>/version"

Gem::Specification.new do |spec|
  spec.name        = "<%= @gem_name %>"
  spec.version     = Nesta::Plugin::<%= module_name %>::VERSION
  spec.authors     = ["TODO: Your name"]
  spec.email       = ["TODO: Your email address"]
  spec.homepage    = ""
  spec.summary     = %q{TODO: Write a gem summary}
  spec.description = %q{TODO: Write a gem description}
  spec.license     = "MIT"

  spec.rubyforge_project = "<%= @gem_name %>"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }       
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/}) 
  spec.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # spec.add_development_dependency "rspec"
  # spec.add_runtime_dependency "rest-client"
  spec.add_dependency("nesta", ">= 0.9.11")
  spec.add_development_dependency("rake")
end
