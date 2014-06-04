#!/usr/bin/env ruby
begin
  require 'pcaper'
rescue LoadError
  $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  require 'pcaper'
end
require 'sinatra'
require 'haml'
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'web_helpers'
require 'carve_record'
require 'fileutils'
require File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'worker'))

if Pcaper::Config.webdb.database_type == :sqlite
  begin
    chkfile = File.join(File.dirname(Pcaper::Config.webdbfile), '.chkperm')
    File.open(chkfile, 'w') {|fh| fh.puts 'test'}
    FileUtils.rm_f(chkfile)
  rescue Errno::EACCES
    raise "web_db must be in a writable directory! (dirname: #{File.dirname(Pcaper::Config.webdbfile)})"
  end
end

begin 
  FileUtils.mkdir_p(Pcaper::Config.web_carve_dir) unless File.exist?(Pcaper::Config.web_carve_dir)
  chkfile = File.join(Pcaper::Config.web_carve_dir, '.chkperm')
  File.open(chkfile, 'w') {|fh| fh.puts 'test'}
  FileUtils.rm_f(chkfile)
rescue Errno::EACCES
  raise "web_carve_dir must be a writable directory! (dirname: #{Pcaper::Config.web_carve_dir})"
end

helpers WebHelpers

configure do
  mime_type :pcap, 'application/vnd.tcpdump.pcap'
end

get '/' do
  redirect '/find'
end

get '/find' do
  req_params = %w{ start_time src dst }
  params_set = (params.find_all{|k,v|!v.empty?}).collect{|k,v| k}
  if (req_params - params_set).empty?
    begin
      @carver = carver_for_params(params)
      unless @carver.records_found?
        raise ArgumentError, "No db records was found at this time"
      end
      @sessions = @carver.session_find
    rescue ArgumentError => e
      @err = e.message
    end
  else
    @err = "All required fields (#{req_params.join(', ')}) must be set" unless params_set.empty?
  end

  if request.xhr?
    haml :find_table, :layout => false
  else
    haml :find
  end
end

get '/carve' do
  begin
    @rec = CarveRecord.new(params)
    unless @rec.carve_record_found?
      carver = carver_for_params(params)
      if carver.session_find.empty?
        @err = "no sessions where found."
      else
        @rec.add
        Thread.new { Worker.run } unless Pcaper::Config.web_standalone_worker
      end
    end
  rescue => e
    @err = e.class.to_s + ": " + e.message
  end
  haml :carve
end

get '/download/:chksum' do
  row = Pcaper::Config.webdb[:carve].where(:chksum => params[:chksum], :worker_state => 'done').first
  raise Sinatra::NotFound unless row
  row_params = JSON::load(row[:params])
  filename = [ row_params['src'], row_params['sport'] ].join(":")
  filename += "_" + [ row_params['dst'], row_params['dport'] ].join(":") + ".pcap"
  send_file row[:local_file], :type => 'pcap', :filename => filename
end

