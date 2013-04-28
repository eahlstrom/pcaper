#!/usr/bin/env ruby
require 'rubygems'
begin
  require 'pcaper'
rescue LoadError
  $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
  require 'pcaper'
end

require 'pp'
require 'ostruct'
require 'optparse'
require 'fileutils'
include FileUtils

options = OpenStruct.new
options.recs_around = 5
options.verbose = false
options.dry_run = false

opts = OptionParser.new('Usage: carve_pcap.rb [options]', 30, ' ') do |opts|
  opts.separator "Options:"

  opts.on('-p', '--ip-proto PROTO', %{(R) ip protocol.}) do |arg|
    options.proto = arg
  end

  opts.on('-S', '--source HOST', %{(R) source host.}) do |arg|
    options.src_host = arg
  end

  opts.on('-s', '--source-port PORT', %{(R) source port.}) do |arg|
    options.src_port = arg
  end

  opts.on('-D', '--destination HOST', %{(R) destination host.}) do |arg|
    options.dst_host = arg
  end

  opts.on('-d', '--destination-port PORT', %{(R) destination port.}) do |arg|
    options.dst_port = arg
  end

  opts.on('-A', '--records-around NUM', %{(O) Look for session in NUM files around match.}) do |arg|
    options.recs_around = arg 
  end

  opts.on('-r', '--devices DEV[,DEV,..]', %{(O) limit to a specific device.}) do |arg|
    options.devices = arg.split(",")
  end

  opts.on('-v', '--verbose', %{(O) verbose output.}) do |bool|
    options.verbose = bool
  end

  opts.on('-n', '--dry-run', %{(O) Just show steps. (implies -v)}) do |bool|
    options.dry_run = bool
    options.verbose = true
  end

  opts.separator ""
  opts.separator "Default:"
  opts.separator "  records-around - #{options.recs_around}"
  opts.separator ""


  opts.separator ""
  opts.separator "Examples:"
  opts.separator "  carve_pcap.rb -p tcp -S 10.0.0.1 -s 12345 -D 10.0.0.10 -d 22 1367070618"
  opts.separator "  carve_pcap.rb -r eth0,eth2 -p tcp -S 10.0.0.1 -s 12345 -D 10.0.0.10 -d 22 1367070618"
  opts.separator ""
end

begin
  opts.parse!
  [:proto, :src_host, :src_port, :dst_host, :dst_port].each do |k|
    raise OptionParser::InvalidOption, "Required option: #{k.inspect}" if options.send(k).nil?
  end
rescue OptionParser::InvalidOption => e
  print e.message + "\n\n" unless e.message.empty?
  puts opts.help
  exit 1
end

fopts = {
  :verbose => options.verbose,
  :noop => options.dry_run,
}

carver = Pcaper::Carve.new(
  :start_time => ARGV.join(' '),
  :proto      => options.proto,
  :src_host   => options.src_host,
  :src_port   => options.src_port,
  :dst_host   => options.dst_host,
  :dst_port   => options.dst_port,
  :records_around => options.recs_around,
  :verbose    => options.verbose,
)

def human_time(usec)
  Time.at(usec.to_i).strftime("%Y-%m-%d %T")
end

printf "Querying between: %s -> %s\n\n", human_time(carver.query_start), human_time(carver.query_end)

puts "Found rows:"
carver.session_find.each do |r|
  printf "%s -> %s | %s:%s -> %s:%s, proto: %s, state: %s", 
    human_time(r[:stime]), human_time(r[:ltime]), r[:saddr], r[:sport],
    r[:daddr], r[:dport], r[:proto], r[:state]
end
puts

