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

options = OpenStruct.new
options.verbose = false
options.q_scope = nil
options.check_files = false

opts = OptionParser.new('Usage: verify.rb [options]', 30, ' ') do |opts|
  opts.separator "Options:"

  opts.on('-s', '--scope STARTTIME..ENDTIME', %{(O) Set query timescope.}) do |arg|
    options.q_scope = arg.split("..").collect{|t| Time.parse(t)}
  end

  opts.on('-T', '--scope-today', %{(O) Set query timescope to this day.}) do |bool|
    options.q_scope = [ Time.parse(Time.now.strftime("%Y-%m-%d 00:00")), Time.parse(Time.now.strftime("%Y-%m-%d 23:59:59")) ]
  end

  opts.on('-f', '--check-files', %{(O) Verify on files on disc.}) do |bool|
    options.check_files = bool
  end

  opts.on('-F', '--remove-db-rows', %{(O) Remove db rows without pcap on disc. (implies -f)}) do |bool|
    options.remove_db_rows = bool
  end

  opts.on('-v', '--verbose', %{(O) verbose output.}) do |bool|
    options.verbose = bool
  end

  opts.on('-n', '--dry-run', %{(O) Just show steps. (implies -v)}) do |bool|
    options.dry_run = bool
    options.verbose = true
  end

  opts.separator ""
  opts.separator "Example:"
  opts.separator '  verify.rb -vf'
  opts.separator '  verify.rb -s "2013-04-19 10:00..2013-04-20 00:00"'
  opts.separator ""
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

def out(id, msg)
  printf("%05d - %s\n", id, msg)
end

def epoch2human(usecs)
  Time.at(usecs).strftime("%Y-%m-%d %T")
end

def magic(file)
  File.read(file,4).unpack("H*").first
end

limit = 50
total_size_on_disc = 0
scope = Pcaper::Models::Pcap.select(:id, :start_time, :end_time, :filename, :filesize, :argus_file)
if options.q_scope
  scope = scope.where(:start_time => (options.q_scope[0].to_i)..(options.q_scope[1].to_i))
end

if options.check_files
  0.step(scope.count, limit) do |offset|
    scope.limit(limit, offset).each do |r|
      puts "checking file #{r[:filename]}" if options.verbose
      # pcap checks
      if r[:filename] && File.exist?(r[:filename])
        unless magic(r[:filename]) == 'd4c3b2a1'
          out r[:id], "invalid file type: #{r[:filename]}. magic != 0xd4c3b2a1"
        end
        on_disk_size = File.stat(r[:filename]).size
        total_size_on_disc += on_disk_size
        unless r[:filesize] == on_disk_size
          out r[:id], "filesize(#{on_disk_size}) != db filesize(#{r[:filesize]}): #{r[:filename]}"
        end
      else
        out r[:id], "No file: #{r[:filename]}"
        if options.remove_db_rows
          Pcaper::Models::Pcap.where(:id => r[:id]).delete unless options.dry_run
        end
      end
      
      # argus checks
      if r[:argus_file] && File.exist?(r[:argus_file])
        unless magic(r[:argus_file]) == '83100020'
          out r[:id], "invalid file type: #{r[:argus_file]}. magic != 0x83100020"
        end
      else
        out r[:id], "No file: #{r[:argus_file]}"
      end
    end
  end
end

if options.q_scope
  printf "==== STAT starttime between '%s' and '%s' ====\n", epoch2human(options.q_scope[0]), epoch2human(options.q_scope[1])
else
  printf "==== STAT ====\n"
end
printf "  Total records       - %s\n", scope.count
if scope.count > 0
  printf "  Total size (db)     - %.02f GB (%d bytes)\n", scope.sum(:filesize).to_f / 1024 / 1024 / 1024, scope.sum(:filesize)
  printf "  True size on disc   - %.02f GB (%d bytes)\n", total_size_on_disc.to_f / 1024 / 1024 / 1024, total_size_on_disc if options.check_files
  printf "  First packet seen   - %s\n", epoch2human(scope.min(:start_time))
  printf "  Last packet seen    - %s\n", epoch2human(scope.max(:end_time))
end

