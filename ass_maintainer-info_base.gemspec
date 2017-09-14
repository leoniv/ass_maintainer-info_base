# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ass_maintainer/info_base/version'

Gem::Specification.new do |spec|
  spec.name          = "ass_maintainer-info_base"
  spec.version       = AssMaintainer::InfoBase::VERSION
  spec.authors       = ["Leonid Vlasov"]
  spec.email         = ["leoniv.vlasov@gmail.com"]

  spec.summary       = %q{Manipulate with 1C:Enterprise application instances}
  spec.description   = %q{Classes and utils for manipulate with 1C:Enterprise application instances also known as "InfoBase" or "Information Base"}
  spec.homepage      = "https://github.com/leoniv/ass_maintainer-info_base"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ass_launcher", "~> 0.3"
  spec.add_dependency "net-ping", "~> 2.0.0"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "mocha"

end
