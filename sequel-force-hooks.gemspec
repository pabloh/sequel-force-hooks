require_relative 'lib/sequel/force-hooks'

Gem::Specification.new do |spec|
  spec.name          = 'sequel-force-hooks'
  spec.version       = Sequel::ForceHooks::VERSION
  spec.authors       = ['Pablo Herrero']
  spec.email         = ['pablodherrero@gmail.com']

  spec.summary       = 'Sequel extension that allows savepoints to force running after_commit and after_rollback hooks'
  spec.homepage      = 'https://github.com/pabloh/sequel-force-hooks'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 1.9.2')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/pabloh/sequel-force-hooks'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'

  spec.add_dependency 'sequel', '~> 5.28'
end
