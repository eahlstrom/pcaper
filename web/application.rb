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

helpers WebHelpers

configure do
  set :public_folder, File.dirname(__FILE__) + '/static'
  mime_type :pcap, 'application/vnd.tcpdump.pcap'
end

get '/' do
  redirect '/find'
end

get '/find' do
  req_params = %w{ start_time proto src dst }
  params_set = (params.find_all{|k,v|!v.empty?}).collect{|k,v| k}
  if (req_params - params_set).empty?
    begin
      @carver = carver_for_params(params)
      @sessions = @carver.session_find
    rescue ArgumentError => e
      @err = e.message
    end
  else
    @err = 'All parmeters must be set' if params_set.length >= 2
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
