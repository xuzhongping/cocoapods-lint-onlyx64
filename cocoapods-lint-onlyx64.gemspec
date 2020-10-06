# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-lint-onlyx64/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-lint-onlyx64'
  spec.version       = CocoapodsLintOnlyx64::VERSION
  spec.authors       = ['nakahira']
  spec.email         = ['1021057927@qq.com']
  spec.description   = %q{A short description of cocoapods-lint-onlyx64.}
  spec.summary       = %q{A longer description of cocoapods-lint-onlyx64.}
  spec.homepage      = 'https://github.com/xuzhongping/cocoapods-lint-onlyx64'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_dependency 'cocoapods', '1.9.3'
end
