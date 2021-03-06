# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "leo_manager_client"

Gem::Specification.new do |gem|
  gem.name          = "leo_manager_client"
  gem.version       = LeoManager::VERSION
  gem.authors       = ["Yosuke Hara"]
  gem.email         = ["leofaststorage@gmail.com"]
  gem.description   = %q{Client for LeoFS-Manager}
  gem.summary       = %q{Client for LeoFS-Manager}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
