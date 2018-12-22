
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'meta/version'

Gem::Specification.new do |spec|
  spec.name          = Meta::GEM_NAME
  spec.version       = Meta::VERSION
  spec.date             = Time.new.strftime("%Y-%m-%d")
  spec.authors       = ["OmG3r"]
  spec.email         = ["adam.boulila@live.fr"]
  spec.files            = Dir['lib/   *.rb'] + Dir['bin/*'] + Dir['lib/meta/*rb'] + Dir['lib/blueprints/*json']
  spec.summary       = %q{A steambot library to manage steam trading offers.}
  spec.description   = %q{Send steam trading offers, generate steam 2FA codes, confirm steam trade offers, get inventories,count badges, collect Sale cards}
  spec.homepage      = "https://github.com/OmG3r/steam-trade/"
  spec.license       = "GPL-3.0"



  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "mechanize", '~> 2.7', '>= 2.7.0'
end
