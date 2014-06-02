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

module Pcaper
  unless defined?(CONFIG_FILE)
    if ENV['PCAPER_CONF'] && File.exist?(ENV['PCAPER_CONF'])
      CONFIG_FILE = ENV['PCAPER_CONF']
    elsif File.exist?(File.join(ENV['HOME'], '.pcaper', 'config.yml'))
      CONFIG_FILE = File.join(ENV['HOME'], '.pcaper', 'config.yml')
    else File.exist?('/etc/pcaper/config.yml')
      CONFIG_FILE = '/etc/pcaper/config.yml'
    end
  end

  CONFIG = YAML::load_file(CONFIG_FILE)                             unless defined?(CONFIG)
  DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))   unless defined?(DIR)
  DB = Sequel.sqlite(Pcaper::CONFIG[:db])                           unless defined?(DB)
  WEBDB = Sequel.sqlite(Pcaper::CONFIG[:web_db])                    unless defined?(WEBDB)

  module Models
  end
end
Sequel::Model.db = Pcaper::DB

require 'pcaper/helpers'
require 'pcaper/ip_helpers'
require 'pcaper/config'
require 'pcaper/capinfo'
require 'pcaper/find_closed_pcaps'
require 'pcaper/models/pcap'
require 'pcaper/carve'
