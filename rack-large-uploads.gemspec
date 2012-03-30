# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack/large-uploads/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Corey Innis"]
  gem.email         = ["corey@coolerator.net"]
  gem.description   = %q{Rack middleware for handling large file uploads. Integrates nicely with the Nginx upload module: http://www.grid.net.ru/nginx/upload.en.html}
  gem.summary       = %q{Rack middleware for handling large file uploads}
  gem.homepage      = "https://github.com/coreyti/rack-large-uploads"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rack-large-uploads"
  gem.require_paths = ["lib"]
  gem.version       = Rack::LargeUploads::VERSION

  gem.required_ruby_version = ">= 1.9"
  gem.add_development_dependency "bundler"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rr"
  gem.add_development_dependency "simplecov"

  # TODO: remove dependencies on these:
  gem.add_runtime_dependency "actionpack"
  gem.add_runtime_dependency "activesupport"
end
