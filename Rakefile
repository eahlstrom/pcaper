require 'rake/testtask'
task :default => 'test:all'

namespace :test do

  Rake::TestTask.new('all') do |t|
    t.pattern = "test/test_*.rb"
  end

  Rake::TestTask.new('libs') do |t|
    t.pattern = "test/test_lib_*.rb"
  end

  Rake::TestTask.new('testbed') do |t|
    t.pattern = "test/test_testbed_*.rb"
  end

  Rake::TestTask.new('programs') do |t|
    t.pattern = "test/test_program_*.rb"
  end
 
end
