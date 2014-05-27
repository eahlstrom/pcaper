require 'rake/testtask'
task :default => :test

Rake::TestTask.new('test') do |t|
  t.pattern = "test/test_*.rb"
end

Rake::TestTask.new('test:testbench') do |t|
  t.pattern = "test/test_pcaper_module_init.rb"
end
