require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'

$:.unshift File.dirname(__FILE__) + '/lib'
require 'appkernel'


# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'appkernel' do
  self.developer 'Charles Lowell', 'cowboyd@thefrontside.net'
end

task :default => :spec