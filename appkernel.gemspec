# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{appkernel}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Charles Lowell"]
  s.date = %q{2009-07-01}
  s.description = %q{AppKernel is a microframework for capturing your application in terms of minute, self-validating functions. 
Once defined, these functions can be used in rails, cocoa, an sms gateway, or wherever you want to take them.}
  s.email = ["cowboyd@thefrontside.net"]
  s.extra_rdoc_files = ["istory.txt", "Manifest.txt", "PostInstall.txt"]
  s.files = ["istory.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "lib/appkernel.rb", "lib/appkernel/function.rb", "lib/appkernel/validation.rb", "script/console", "script/destroy", "script/generate", "spec/appkernel/function_spec.rb", "spec/appkernel/validation_spec.rb", "spec/spec.opts", "spec/spec_helper.rb"]
  s.homepage = %q{http://github.com/cowboyd/appkernel}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{appkernel}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{AppKernel is a microframework for capturing your application in terms of minute, self-validating functions}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 2.3.2"])
    else
      s.add_dependency(%q<hoe>, [">= 2.3.2"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 2.3.2"])
  end
end
