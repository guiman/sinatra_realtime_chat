require 'rubygems'
require 'bundler'
require 'rake/testtask'

Bundler.require(:default, :test)

task :default => 'test'

Rake::TestTask.new('test') do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end