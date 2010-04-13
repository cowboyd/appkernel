require 'rubygems'

$gemspec = Gem::Specification.new do |gemspec|
  manifest = Rake::FileList.new("**/*")
  manifest.exclude "**/*.gem"  
  gemspec.name = "appkernel"
  gemspec.version = "0.3.0"
  gemspec.summary = "Functional Programming by Contract for Ruby"
  gemspec.description = "validate, call, and curry your way to fun and profit!"
  gemspec.email = "cowboyd@thefrontside.net"
  gemspec.authors = ["Charles Lowell"]
  gemspec.require_paths = ["lib"]
  gemspec.files = manifest.to_a
end

desc "Build gem"
task :gem do
  Gem::Builder.new($gemspec).build
end

desc "Build gemspec"
task :gemspec do
  File.open("#{$gemspec.name}.gemspec", "w") do |f|
    f.write($gemspec.to_ruby)
  end
end

task :clean do
  sh "rm -rf *.gem"
end


for file in Dir['tasks/*.rake']
  load file
end


