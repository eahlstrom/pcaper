require 'rake/testtask'
task :default => 'test:all'

namespace :test do

  desc 'run all tests'
  task :all => [:testbed, :libs, :programs]

  Rake::TestTask.new('libs') do |t|
    t.pattern = "test/test_lib_*.rb"
  end

  Rake::TestTask.new('testbed') do |t|
    t.pattern = "test/test_testbed_*.rb"
  end

 
  # programs must run independently 
  # since it destroy the db for eachother.
  desc 'run programs'
  task 'programs' do
    FileList['test/test_program_*.rb'].each do |file|
      puts ""
      puts "=== running program #{file} ==="
      puts ""
      ruby "-Ilib", file
      puts
    end
  end

end
