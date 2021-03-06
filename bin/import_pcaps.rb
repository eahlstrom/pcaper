#!/usr/bin/env ruby
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

$options = OpenStruct.new
$options.dst_dir = nil
$options.pcap_glob = '*.pcap'
$options.db_file = nil
$options.device_regx = '(eth\d+)'
$options.verbose = false
$options.dry_run = false

opts = OptionParser.new('Usage: import_pcaps.rb [options] pcaps_directory', 30, ' ') do |opts|
  opts.separator "Options:"
  opts.on('-d', '--dst-dir DIR', %{(O) move pcap's. (default: no move)}) do |dir|
    $options.dst_dir = dir
  end

  opts.on('-p', '--pcap-name GLOB', %{(O) pcap name glob to find pcap with. (default: #{$options.pcap_glob})}) do |glob|
    $options.pcap_glob = glob
  end

  opts.on('-R', '--device-regexp REGX', %{(O) Regexp to fetch device name.}) do |regexp|
    $options.device_regx = regexp
  end

  opts.on('-v', '--verbose', %{(O) verbose output.}) do |bool|
    $options.verbose = bool
  end

  opts.on('-n', '--dry-run', %{(O) Just show steps. (implies -v)}) do |bool|
    $options.dry_run = bool
    $options.verbose = true
  end

  opts.separator ""
  opts.separator "pcaps_directory:"
  opts.separator "  should be the directory containing pcaps or - for reading each file from STDIN"
  opts.separator ""
  opts.separator "Examples:"
  opts.separator "  import_pcaps.rb -d /opt/archive/{device}/%Y/%m/%d /opt/pcap/eth0"
end

begin
  opts.parse!
  $options.src_dir = ARGV[0]
rescue OptionParser::InvalidOption => e
  print e.message + "\n\n" unless e.message.empty?
  puts opts.help
  exit 1
end



def process_file(pcap_file)
  fopts = {
    :verbose => $options.verbose,
    :noop => $options.dry_run,
  }
  dev_regx = Regexp.new($options.device_regx)
  printf "\nProcessing #{pcap_file}...\n" if $options.verbose

  if Pcaper::Models::Pcap.pcap_imported?(pcap_file)
    puts "#{pcap_file} already imported" if $options.verbose
    return
  end

  device = dev_regx.match(pcap_file) ? $~.captures.first : ''

  capinfo = Pcaper::Capinfo.capinfo(pcap_file)
  if capinfo.empty? || capinfo[:num_packets] == 0
    puts "pcap empty, skipping"
    return
  end

  if $options.dst_dir
    dst_dir = Time.at(capinfo[:start_time].to_i).strftime($options.dst_dir).gsub(/\{device\}/, device)
    mkdir_p(dst_dir, fopts) unless File.exist?(dst_dir)
    mv(pcap_file, dst_dir, fopts)
  else
    dst_dir = File.dirname(pcap_file)
  end

  capinfo[:filename] = File.expand_path(File.join(dst_dir, File.basename(pcap_file)))
  puts "Adding #{pcap_file} (#{capinfo[:sha1sum]}) to db..." if $options.verbose
  unless $options.dry_run
    begin
      retries ||= 3
      pcap = Pcaper::Models::Pcap.new(capinfo)
      pcap.device = device
      pcap.save
    rescue Sequel::DatabaseConnectionError => e
      unless (retries -= 1).zero?
        puts e.message
        sleep 1
        retry
      end
    rescue => e
      mv(capinfo[:filename], File.dirname(pcap_file), fopts) if File.exist?(capinfo[:filename])
      $stderr.puts "Import failed for pcap_file. Failure msg: '#{e.message}', capinfo: #{capinfo.inspect}"
      return
    end
  end
  puts if $options.verbose
end

if $options.src_dir == "-"
  $stdin.each_line do |pcap_file|
    process_file(pcap_file.chomp)
  end
else
  Pcaper::FindClosedPcaps.files($options.src_dir, $options.pcap_glob) do |pcap_file|
    process_file(pcap_file)
  end
end

