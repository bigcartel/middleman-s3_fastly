# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = 'middleman-s3_fastly'
  gem.version       = '0.2.0'
  gem.authors       = ['Big Cartel']
  gem.email         = ['dev@bigcartel.com']
  gem.description   = %q(A simple wrapper for standardizing middleman deploys to s3 and fastly)
  gem.summary       = %q(Uses s3_sync to push site files to s3, issues purges to fastly after deploy, and reads configuration data from chef)

  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'middleman-core', '>= 4.1.8'
  gem.add_runtime_dependency 'middleman-s3_sync', '>= 4.0.0'
  gem.add_runtime_dependency 'fastly', '>= 1.4.0'
end
