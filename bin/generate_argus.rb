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
options.dst_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'argus', '{device}', '%Y', '%m', '%d'))
options.argus_opts = '-U 100'
options.device_regx = '(eth\d+)'
options.verbose = false
options.dry_run = false

opts = OptionParser.new('Usage: generate_argus.rb [options]', 25, ' ') do |opts|
  opts.separator "Options:"
  opts.on('-d', '--dst-dir DIR', %{(O) Where to put the generated files.}) do |dir|
    options.dst_dir = dir
  end

  opts.on('-A', '--argus OPTS', %{(O) Extra options to add to argus.}) do |opts|
    options.argus_opts = opts
  end

  opts.on('-R', '--device-regexp REGX', %{(O) Regexp to fetch device name.}) do |regexp|
    options.device_regx = regexp
  end

  opts.on('-v', '--verbose', %{(O) verbose output.}) do |bool|
    options.verbose = bool
  end

  opts.on('-n', '--dry-run', %{(O) Just show steps. (implies -v)}) do |bool|
    options.dry_run = bool
    options.verbose = true
  end

  opts.separator ""
  opts.separator "Default options:"
  opts.separator "  dst-dir       - '#{options.dst_dir}'"
  opts.separator "  argus-options - '#{options.argus_opts}'"
  opts.separator "  device-regexp - '#{options.device_regx}'"

  opts.separator ""
  opts.separator "Examples:"
  opts.separator "  generate_argus.rb -d /opt/archive/{device}/%Y/%m/%d "
end

begin
  opts.parse!
rescue OptionParser::InvalidOption => e
  print e.message + "\n\n" unless e.message.empty?
  puts opts.help
  exit 1
end

fopts = {
  :verbose => options.verbose,
  :noop => options.dry_run,
}

dev_regx = Regexp.new(options.device_regx)
Pcaper::Models::Pcap.where(:argus_file => nil).order(:start_time).each do |pcap|
  pcap_file = pcap.filename
  
  unless File.exist?(pcap_file)
    $stderr.puts "Could not find #{pcap_file}"
    next
  end
  puts "Processing file: #{pcap_file}..." if options.verbose

  device = if dev_regx.match(pcap_file)
             $~.captures.first
           else
             raise "Could not match device with regexp: #{dev_regx.inspect}"
           end

  dst_dir = Time.at(pcap.start_time).strftime(options.dst_dir.gsub(/{device}/i, device))
  dst_file = File.join(dst_dir, File.basename(pcap.filename) + ".argus")

  mkdir_p(dst_dir, fopts) unless File.exist?(dst_dir)
  if File.exist?(dst_file)
    $stderr.puts "dst file: #{dst_file} already exist! Skipping..."
    next
  end

  cmd = %{argus -r #{pcap_file} -w #{dst_file} #{options.argus_opts}}
  puts cmd if options.verbose
  unless options.dry_run
    if system(cmd)
      pcap.argus_file = dst_file
      pcap.save
      cmd = %{racluster -M replace -r #{dst_file}}
      puts cmd if options.verbose
      system(cmd) unless pcap.num_packets == 0 # racluster seqfaults when no packets are in the file
      system(%{touch -r #{pcap_file} #{dst_file}})
    else
      $stderr.puts "Command failed! (#{cmd})"
    end
  end
  puts if options.verbose
end
