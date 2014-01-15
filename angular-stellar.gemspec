# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'angular/stellar/package'

Gem::Specification.new do |spec|
  spec.name          = Angular::Stellar::NAME
  spec.version       = Angular::Stellar::VERSION
  spec.authors       = [Angular::Stellar::AUTHOR["name"]]
  spec.email         = [Angular::Stellar::AUTHOR["email"]]
  spec.summary       = Angular::Stellar::DESCRIPTION
  spec.description   = Angular::Stellar::LONGDESCRIPTION
  spec.homepage      = Angular::Stellar::HOMEPAGE
  spec.license       = Angular::Stellar::LICENSE["type"]

  spec.files         = ["package.json", "LICENSE", "README.md"] + Dir["lib/**/*.rb"] + Dir["vendor/assets/javascripts/*.js"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
