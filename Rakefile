require 'rake/clean'
require 'rake/testtask'

task :default => :test

# TESTS #######################################################################

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/*_test.rb']
end
