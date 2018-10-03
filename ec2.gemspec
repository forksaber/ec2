# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ec2/version'

Gem::Specification.new do |spec|
  spec.name          = "ec2"
  spec.version       = Ec2::VERSION
  spec.authors       = ["Neeraj Bhunwal"]
  spec.email         = ["neeraj.bhunwal@gmail.com"]
  spec.summary       = %q{Integrates ec2 resources with salt}
  spec.description   = %q{Integrates ec2 resources with salt}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'aws-sdk-ec2', '~> 1'
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
