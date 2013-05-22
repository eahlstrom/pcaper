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
require 'carve_db'
require 'fileutils'
require File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'worker'))

begin
  chkfile = File.join(File.dirname(Pcaper::CONFIG[:web_db]), '.chkperm')
  File.open(chkfile, 'w') {|fh| fh.puts 'test'}
  FileUtils.rm_f(chkfile)
rescue Errno::EACCES
  raise "web_db must be in a writable directory! (dirname: #{File.dirname(Pcaper::CONFIG[:web_db])})"
end

begin 
  FileUtils.mkdir_p(Pcaper::CONFIG[:web_carve_dir]) unless File.exist?(Pcaper::CONFIG[:web_carve_dir])
  chkfile = File.join(Pcaper::CONFIG[:web_carve_dir], '.chkperm')
  File.open(chkfile, 'w') {|fh| fh.puts 'test'}
  FileUtils.rm_f(chkfile)
rescue Errno::EACCES
  raise "web_carve_dir must be a writable directory! (dirname: #{Pcaper::CONFIG[:web_carve_dir]})"
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
  logger.info "params: #{params.inspect}"
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
  @db = CarveDatabase.new(params)
  unless @db.working_on_params?
    begin
      @carver = carver_for_params(params)
      @db.add
      Thread.new { Worker.run } unless Pcaper::CONFIG[:standalone_web_workers]
    rescue ArgumentError => e
      @err = e.message
    end
  end
  haml :carve
end

get '/download/:chksum' do
  row = Pcaper::WEBDB[:carve].where(:chksum => params[:chksum]).first
  raise Sinatra::NotFound unless row
  params = JSON::load(row[:params])
  filename = [ params['src'], params['sport'] ].join(":")
  filename += "_" + [ params['dst'], params['dport'] ].join(":") + ".pcap"
  send_file row[:local_file], :type => 'pcap', :filename => filename
end

