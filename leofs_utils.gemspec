# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "leofs_manager_client"

Gem::Specification.new do |gem|
  gem.name          = "leofs_manager_client"
  gem.version       = LeoFSManager::VERSION
  gem.authors       = ["Glass_saga"]
  gem.email         = ["glass.saga@gmail.com"]
  gem.description   = %q{Client for LeoFS Manager}
  gem.summary       = %q{Client for LeoFS Manager}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
