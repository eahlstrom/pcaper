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
  unless defined?(CONFIG_FILE)
    if ENV['PCAPER_CONF'] && File.exist?(ENV['PCAPER_CONF'])
      CONFIG_FILE = ENV['PCAPER_CONF']
    elsif File.exist?(File.join(ENV['HOME'], '.pcaper', 'config.yml'))
      CONFIG_FILE = File.join(ENV['HOME'], '.pcaper', 'config.yml')
    else File.exist?('/etc/pcaper/config.yml')
      CONFIG_FILE = '/etc/pcaper/config.yml'
    end
  end

  default_config = {
    :db             => '/etc/pcaper/pcaps.db',
    :argusdir       => '/opt/pcap/argus/{device}/%Y/%m/%d',
    :web_db         => '/etc/pcaper/web.db',
    :web_carve_dir  => '/opt/pcaper/webcarve',
    :standalone_web_workers => false,
    :tcpdump        => '/usr/sbin/tcpdump',
    :mergecap       => '/usr/bin/mergecap',
    :ra             => '/usr/local/bin/ra',
    :racluster      => '/usr/local/bin/racluster',
    :lsof           => '/usr/sbin/lsof',
    :capinfos       => '/usr/sbin/capinfos',
    :argus          => '/usr/local/sbin/argus',
  }
  begin
    CONFIG = YAML::load_file(CONFIG_FILE) unless defined?(CONFIG)
    default_config.keys.each do |key|
      unless CONFIG.has_key?(key)
        raise ArgumentError, "Config miss key: #{key.inspect}"
      end
    end
    [ :tcpdump, :mergecap, :ra, :racluster, :lsof, :capinfos, :argus].each do |cmd|
      raise ArgumentError,("Could not find cmd: #{cmd} at #{CONFIG[cmd]}") unless File.exist?(CONFIG[cmd])
    end
  rescue Errno::ENOENT
    $stderr.puts "Cound not load config file"
    $stderr.puts "Searched:"
    $stderr.puts " - $PCAPER_CONF"
    $stderr.puts " - ~/.pcaper/config.yml"
    $stderr.puts " - /etc/pcaper/config.yml"
    $stderr.puts ""
    $stderr.puts "Please generate this file first or specify yours"
    $stderr.puts "with the environment variable PCAPER_CONF"
    $stderr.puts
    $stderr.puts "Example config:"
    $stderr.puts "-- snipp --"
    $stderr.puts default_config.to_yaml
    $stderr.puts "-- snipp --"
    exit 127
  rescue ArgumentError => e
    $stderr.puts e.message
    $stderr.puts ""
    $stderr.puts "Example config:"
    $stderr.puts "-- snipp --"
    $stderr.puts default_config.to_yaml
    $stderr.puts "-- snipp --"
    exit 127
  end
end


module Pcaper
  VERSION = "0.0.1"
  DIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))   unless defined?(DIR)
  DB = Sequel.sqlite(Pcaper::CONFIG[:db])                           unless defined?(DB)
  WEBDB = Sequel.sqlite(Pcaper::CONFIG[:web_db])                    unless defined?(WEBDB)

  module Models
  end
end
Sequel::Model.db = Pcaper::DB

require 'pcaper/helpers'
require 'pcaper/ip_helpers'
require 'pcaper/capinfo'
require 'pcaper/find_closed_pcaps'
require 'pcaper/models/pcap'
require 'pcaper/carve'
