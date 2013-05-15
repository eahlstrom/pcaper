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
require File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'worker'))

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
  p params_set
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

# get '/browse' do
#   @pcaps = Pcaper::Models::Pcap.limit(30)
#   haml :browse
# end
