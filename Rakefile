require "rubygems"
require "rake/testtask"

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/test_*.rb"]
  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "nordea-rb"
    gemspec.summary = "Ruby library for accessing your Nordea Bank account and transferring money between your own accounts."
    gemspec.description = "Ruby library for accessing your Nordea Bank account and transferring money between your own accounts."
    gemspec.email = "name@my-domain.se"
    gemspec.homepage = "http://github.com/haraldmartin/nordea-rb"
    gemspec.authors = ["Martin Ström"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
