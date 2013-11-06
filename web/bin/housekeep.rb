#!/usr/bin/env ruby
begin
  require 'pcaper'
rescue LoadError
  $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
  require 'pcaper'
end
require 'logger'
require 'fileutils'
include FileUtils

class Housekeep
  def self.run(log=Logger.new($stdout))
    carve = Pcaper::WEBDB[:carve]
    carve.where{submitted < (Time.now.to_i-600)}.order(:submitted).select(:id, :local_file).each do |row|
      rm_f(row[:local_file]) if File.exist?(row[:local_file])
      carve.where(:id => row[:id]).delete
    end
    carve.where{submitted < (Time.now.to_i-10)}.where('worker_state != "done"').select(:id, :local_file).each do |row|
      rm_f(row[:local_file]) if File.exist?(row[:local_file])
      carve.where(:id => row[:id]).delete
    end
  end
end

if __FILE__ == $0
  log = Logger.new(ARGV[0] || $stdout)
  Housekeep.run(log)
end
