require 'rake/testtask'

task :default => 'test:all'

=begin
namespace :test do

  Rake::TestTask.new('all') do |t|
    t.pattern = "test/test_*.rb"
  end

  Rake::TestTask.new('libs') do |t|
    t.pattern = "test/test_lib_*.rb"
  end

  Rake::TestTask.new('programs') do |t|
    t.pattern = "test/test_program_*.rb"
  end
 
end
=end
task :test do
  Rake::Task['test:all'].invoke
end

namespace :test do
  task :libs do
    Dir.glob("test/test_lib_*.rb").each do |file|
      sh %{ruby -Ilib #{file}}
    end
  end

  task :programs do
    Dir.glob("test/test_program_*.rb").each do |file|
      sh %{ruby -Ilib #{file}}
    end
  end

  task :web do
    Dir.glob("test/test_web_*.rb").each do |file|
      sh %{ruby -Ilib #{file}}
    end
  end

  task :all do
    Rake::Task['test:libs'].invoke
    Rake::Task['test:programs'].invoke
    Rake::Task['test:web'].invoke
  end
end
