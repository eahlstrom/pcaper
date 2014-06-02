begin
require 'sequel'
rescue LoadError
  puts "loading rubygmes"
  require 'rubygems'
  require 'sequel'
end
require 'digest'
require 'yaml'
if Sequel::VERSION >= "4"
  Sequel.extension(:core_extensions) # needed for .order(:start_time.desc)
end

module Pcaper
  VERSION = "0.0.1"
end

require 'pcaper/config'
Pcaper::Config.load unless Pcaper::Config.loaded?
Sequel::Model.db = Pcaper::Config.db

require 'pcaper/helpers'
require 'pcaper/ip_helpers'
require 'pcaper/config'
require 'pcaper/capinfo'
require 'pcaper/find_closed_pcaps'
require 'pcaper/models'
require 'pcaper/carve'
