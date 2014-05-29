require 'rake/testtask'
task :default => 'test:all'

namespace :test do

  desc 'run all tests'
  task :all => [:testbed, :libs, :programs]

  Rake::TestTask.new('libs') do |t|
    t.test_files = FileList.new('test/test_*.rb') do |fl|
      fl.exclude(/(test_program_|test_pcaper_module_init)/)
    end
  end

  Rake::TestTask.new('the testbed') do |t|
    t.name = "testbed"
    t.pattern = "test/test_pcaper_module_init.rb"
  end

  desc 'run programs'
  task 'programs' do
    FileList['test/test_program_*.rb'].each do |file|
      puts "=== running program #{file} ==="
      ruby "-Ilib", file
      puts
    end
  end

end
