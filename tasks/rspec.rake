begin
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new(:spec) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.spec_files = FileList['spec/**/*_spec.rb']
  end
rescue LoadError => e
  desc "Run specs"
  task :spec do
    puts "rspec is required to run specs (gem install rspec)"
  end
end

