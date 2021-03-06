#!/usr/bin/env ruby
begin
  require 'pcaper'
rescue LoadError
  $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
  require 'pcaper'
end
require 'json'
require 'stringio'
require 'logger'
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'web_helpers'
require 'carve_record'
include WebHelpers

class Worker
  def self.run(log=Logger.new($stdout))
    webdb = Pcaper::Config.webdb[:carve]
    webdb.where(:worker_state => 'submitted').each do |row|
      log.info "(#{row[:id]}) processing..."
      webdb.where(:id => row[:id]).update(:worker_state => 'processing')
      params = JSON::load(row[:params])
      log.info "(#{row[:id]}) params set to: #{params.inspect}"
      carver = carver_for_params(params)
      begin
        carver.carve_session(Pcaper::Config.tmp_dir, row[:local_file])
      rescue => e
        webdb.where(:id => row[:id]).update(:finished => Time.now.to_i, :worker_state => 'failed', :worker_msg => e.message)
        log.error "failure! msg: #{e.message}"
        next
      end
      log.info "(#{row[:id]}) done! carved pcap: #{row[:local_file]}"
      webdb.where(:id => row[:id]).update(:finished => Time.now.to_i, :worker_state => 'done')
    end
  end
end

if __FILE__ == $0
  log = Logger.new(ARGV[0] || $stdout)
  loop do
    begin
      Worker.run(log)
    rescue => e
      puts "Err! #{e}"
      next
    ensure
      sleep 1
    end
  end
end
