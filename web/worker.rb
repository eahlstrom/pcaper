#!/usr/bin/env ruby
begin
  require 'pcaper'
rescue LoadError
  $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
  require 'pcaper'
end
require 'json'
require 'stringio'
require File.join(File.dirname(__FILE__), 'web_helpers')
require File.join(File.dirname(__FILE__), 'carve_db')
include WebHelpers

carve = Pcaper::WEBDB[:carve]
loop do
  begin
    carve.where(:worker_state => 'submitted').each do |row|
      carve.where(:id => row[:id]).update(:worker_state => 'processing')
      params = JSON::load(row[:params])
      carver = carver_for_params(params)
      begin
        carver.carve_session(Pcaper::CONFIG[:tmpdir], row[:local_file])
      rescue => e
        carve.where(:id => row[:id]).update(:finished => Time.now.to_i, :worker_state => 'failed', :worker_msg => e.message)
        next
      end
      carve.where(:id => row[:id]).update(:finished => Time.now.to_i, :worker_state => 'done')
    end
  rescue => e
    puts "Err! #{e}"
    next
  ensure
    sleep 1
  end
end
