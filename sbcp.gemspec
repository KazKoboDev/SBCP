# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sbcp/version'

Gem::Specification.new do |spec|
  spec.name          = 'sbcp'
  spec.version       = SBCP::VERSION
  spec.authors       = ['Kazyyk']
  spec.email         = ['kazyyk@gmail.com']

  spec.summary       = %q{SBCP is a Starbound server management solution for Linux.}
  spec.homepage      = 'https://www.kazyyk.com/sbcp'
  spec.license       = 'GNU AGPL v3'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.3.0'

  #spec.add_runtime_dependency 'sinatra', '~> 1.4', '>= 1.4.7'
  #spec.add_runtime_dependency 'sinatra-flash', '~> 0.3.0'
  #spec.add_runtime_dependency 'sinatra-contrib', '~> 1.4', '>= 1.4.7'
  #spec.add_runtime_dependency 'thin', '~> 1.6', '>= 1.6.4'
  #spec.add_runtime_dependency 'sqlite3', '~> 1.3', '>= 1.3.11'
  #spec.add_runtime_dependency 'data_mapper', '~> 1.2'
  #spec.add_runtime_dependency 'dm-sqlite-adapter', '~> 1.2'
  spec.add_runtime_dependency 'celluloid', '~> 0.17.3'
  spec.add_runtime_dependency 'rufus-scheduler', '~> 3.2'
  spec.add_runtime_dependency 'steam-condenser', '~> 1.3', '>= 1.3.11'
  spec.add_runtime_dependency 'rsync', '~> 1.0', '>= 1.0.9'
  spec.add_runtime_dependency 'rbzip2', '~> 0.2.0' # seven_zip_ruby would not compile, using this instead
  spec.add_runtime_dependency 'highline', '~> 1.7', '>= 1.7.8'
  spec.add_runtime_dependency 'time_diff', '~> 0.3.0'


  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rack-test', '~> 0.6.3'
end
