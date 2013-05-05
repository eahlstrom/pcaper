#!/usr/bin/env ruby
begin
  require 'pcaper'
rescue LoadError
  $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
  require 'pcaper'
end
require 'sinatra'
require 'sinatra/content_for'
require 'haml'
require File.join(File.dirname(__FILE__), 'web_helpers')
require File.join(File.dirname(__FILE__), 'carve_db')

helpers WebHelpers

configure do
  set :public_folder, File.dirname(__FILE__) + '/static'
  mime_type :pcap, 'application/vnd.tcpdump.pcap'
end

get '/' do
  redirect '/carve'
end

get '/find' do
  req_params = %w{ start_time proto src sport dst dport }
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

  haml :find
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

# get '/browse' do
#   @pcaps = Pcaper::Models::Pcap.limit(30)
#   haml :browse
# end
