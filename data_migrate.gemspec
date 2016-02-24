# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "data_migrate/version"

Gem::Specification.new do |s|
  s.name        = "data_migrate"
  s.version     = DataMigrate::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Andrew J Vargo", "Ilya Katz"]
  s.email       = ["ajvargo@computer.org", "ilyakatz@gmail.com"]
  s.homepage    = "http://ajvargo.com"
  s.summary     = %q{Rake tasks to migrate data alongside schema changes.}
  s.description = %q{Rake tasks to migrate data alongside schema changes.}
  s.license     = "MIT"

  s.rubyforge_project = "data_migrate"

  s.add_dependency('rails', '>= 4.0')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
