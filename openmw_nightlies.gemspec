# frozen_string_literal: true

require_relative 'lib/openmw_nightlies/version'

Gem::Specification.new do |spec|
  spec.name          = "openmw_nightlies"
  spec.version       = OpenmwNightlies::VERSION
  spec.authors       = ["Alexander Olofsson"]
  spec.email         = ["ace@haxalot.com"]

  spec.summary       = 'A helper for OpenMW nightlies'
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'nokogiri'
  spec.add_dependency 'sinatra'

  # For the Sinatra::Reloader
  spec.add_development_dependency 'sinatra-contrib'
end
