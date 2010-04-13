# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{appkernel}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Charles Lowell"]
  s.date = %q{2010-04-13}
  s.description = %q{validate, call, and curry your way to fun and profit!}
  s.email = %q{cowboyd@thefrontside.net}
  s.files = ["appkernel.gemspec", "History.txt", "lib", "lib/appkernel", "lib/appkernel/curry.rb", "lib/appkernel/function.rb", "lib/appkernel/tap.rb", "lib/appkernel/types.rb", "lib/appkernel.rb", "PostInstall.txt", "Rakefile", "README.rdoc", "script", "script/console", "script/destroy", "script/generate", "spec", "spec/appkernel", "spec/appkernel/curry_spec.rb", "spec/appkernel/function_spec.rb", "spec/appkernel/types_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "tasks", "tasks/rspec.rake"]
  s.homepage = %q{http://github.com/cowboyd/appkernel}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{appkernel}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Functional Programming by Contract for Ruby}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
