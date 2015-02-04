# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "middleman-s3_fastly"
  gem.version       = "0.1.0"
  gem.authors       = ["Lee Jensen"]
  gem.email         = ["lee@bigcartel.com"]
  gem.description   = %q(A simple wrapper for standardizing middleman deploys to s3 and fastly)
  gem.license       = "BSD"

  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'middleman-core'
  gem.add_runtime_dependency 'middleman-s3_sync'
end
