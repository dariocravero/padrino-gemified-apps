# -*- encoding: utf-8 -*-
require File.expand_path('../lib/gemified-app/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Darío Javier Cravero"]
  gem.email         = ["dario@uxtemple.com"]
  gem.description   = %q{Padrino gemified app example}
  gem.summary       = %q{Padrino gemified app example}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "gemified-app"
  gem.require_paths = ["lib", "app", "models"]
  gem.version       = GemifiedApp::VERSION

  gem.add_dependency 'padrino-core'
  gem.add_dependency 'padrino-helpers'
  gem.add_dependency 'slim'
  gem.add_dependency 'sqlite3'
  gem.add_dependency 'sequel'
  gem.add_development_dependency 'rake'
end
