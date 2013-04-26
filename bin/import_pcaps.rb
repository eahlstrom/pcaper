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

ARGV << '--help' if ARGV.empty?

options = OpenStruct.new
options.dst_dir = nil
options.pcap_glob = '*.pcap'
options.db_file = nil
options.verbose = false
options.dry_run = false
options.relative_dstdir = true

opts = OptionParser.new('Usage: import_pcaps.rb [options] pcaps_directory', 22, ' ') do |opts|
  opts.separator "Options:"
  opts.on('-d', '--dst-dir DIR', %{(O) move pcap's. (default: no move)}) do |dir|
    options.dst_dir = dir
    options.relative_dstdir = ! /^\//.match(dir)
  end

  opts.on('-p', '--pcap-name GLOB', %{(O) pcap name glob to find pcap with. (default: #{options.pcap_glob})}) do |glob|
    options.glob = glob
  end

  opts.on('-v', '--verbose', %{(O) verbose output.}) do |bool|
    options.verbose = bool
  end

  opts.on('-S', '--dry-run', %{(O) Just show steps. (implies -v)}) do |bool|
    options.dry_run = bool
    options.verbose = true
  end

  opts.separator ""
  opts.separator "Examples:"
  opts.separator "  import_pcaps.rb -d /opt/archive/eth0/%Y/%m/%d /opt/pcap/eth0"
end

begin
  opts.parse!
  options.src_dir = ARGV[0]
  File.stat(options.src_dir)
rescue OptionParser::InvalidOption => e
  print e.message + "\n\n" unless e.message.empty?
  puts opts.help
  exit 1
end

fopts = {
  :verbose => options.verbose,
  :noop => options.dry_run,
}

Pcaper::FindClosedPcaps.files(options.src_dir, options.pcap_glob) do |pcap_file|
  if Pcaper::Models::Pcap.pcap_imported?(pcap_file)
    puts "#{pcap_file} already imported" if options.verbose
    next
  end

  capinfo = Pcaper::Capinfo.capinfo(pcap_file)

  if options.dst_dir
    dst_dir = Time.at(capinfo[:start_time].to_i).strftime(options.dst_dir)
    if options.relative_dstdir
      dst_dir = File.join(options.src_dir, dst_dir)
    end
    mkdir_p(dst_dir, fopts) unless File.exist?(dst_dir)
    mv(pcap_file, dst_dir, fopts)
  else
    dst_dir = File.dirname(pcap_file)
  end

  capinfo[:filename] = File.expand_path(File.join(dst_dir, File.basename(pcap_file)))
  puts "Adding #{pcap_file} (#{capinfo[:sha1sum]}) to db..." if options.verbose
  Pcaper::Models::Pcap.add_capinfo(capinfo) unless options.dry_run
end

