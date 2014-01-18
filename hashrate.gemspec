Gem::Specification.new do |s|
  s.name        = 'hashrate'
  s.version     = '0.0.2'
  s.date        = '2014-01-18'
  s.summary     = "Bitcoin mining profit calculator"
  s.description = "A calculator for expected bitcoin mining profit based on the future difficulty of the blockchain"
  s.authors     = ["Christian Genco"]
  s.email       = 'christian.genco@gmail.com'
  s.files       = ["lib/hashrate.rb"]
  s.homepage    =
    'http://rubygems.org/gems/hola'
  s.license       = 'MIT'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'linefit'
  s.add_runtime_dependency 'open-uri'
end
