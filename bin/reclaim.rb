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

options = OpenStruct.new
options.verbose = false
options.dry_run = false
options.bytes = nil
options.aggressive = false
options.del_argus_files = false

opts = OptionParser.new('Usage: reclaim.rb [options] bytes', 30, ' ') do |opts|
  opts.separator "Options:"

  opts.on('-A', '--aggressive', %{(O) Reclaim at least X bytes. (default: max X bytes)}) do |bool|
    options.aggressive = bool
  end

  opts.on('-D', '--delete-argus', %{(O) Delete argus files. (default: false)}) do |bool|
    options.del_argus_files = bool
  end

  opts.on('-v', '--verbose', %{(O) verbose output.}) do |bool|
    options.verbose = bool
  end

  opts.on('-n', '--dry-run', %{(O) Just show steps. (implies -v)}) do |bool|
    options.dry_run = bool
    options.verbose = true
  end

  opts.separator ""
  opts.separator "Examples:"
  opts.separator "  reclaim.rb -v 1GB     # will delete pcap files up to 1GB"
  opts.separator "  reclaim.rb -v 100MB   # will delete pcap files up to 100MB"
  opts.separator "  reclaim.rb -A 100MB   # will delete at least 100MB pcap files, probably more"
end

begin
  ARGV << '--help' if ARGV.empty?
  opts.parse!
  case ARGV.join
    when /(\d+)\s*GB/i
      options.bytes = $1.to_i * 1024 * 1024 * 1024
    when /(\d+)\s*MB/i
      options.bytes = $1.to_i * 1024 * 1024
    else
      raise OptionParser::InvalidOption, "invalid byte specifier"
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

scope = Pcaper::Models::Pcap.select(:id, :start_time, :filename, :filesize, :argus_file).exclude(:filename => nil).order(:start_time)
reclaimed_bytes = 0
0.step(Pcaper::Models::Pcap.count, 10) do |offset|
  last_filesize = 0
  scope.limit(10, offset).each do |r|
    last_filesize = r[:filesize]
    break if !options.aggressive && (reclaimed_bytes+last_filesize) >= options.bytes
    FileUtils.rm_f(r[:filename], fopts)
    FileUtils.rm_f(r[:argus_file], fopts) if options.del_argus_files
    Pcaper::Models::Pcap.where(:id => r[:id]).delete unless options.dry_run
    reclaimed_bytes += r[:filesize]
    break if options.aggressive && reclaimed_bytes >= options.bytes
  end

  if !options.aggressive && (reclaimed_bytes+last_filesize) >= options.bytes
    break
  elsif options.aggressive && reclaimed_bytes >= options.bytes
    break
  end
end


puts "Reclaimed #{reclaimed_bytes/1024/1024} MBytes"
