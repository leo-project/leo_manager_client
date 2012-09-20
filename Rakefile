require 'rubygems'
require 'rake'
require "bundler/gem_tasks"
require 'rspec/core'
require 'rspec/core/rake_task'

task :default => :spec

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "-c -f d --tty"
end
