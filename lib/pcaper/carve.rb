require 'fileutils'
require 'tmpdir'

class Pcaper::Carve
  include Pcaper::IPHelpers
  include Pcaper::Helpers
  include Pcaper::ExternalCommands

  attr_reader :start_time, :proto, :src_host, :src_port, :dst_host, :dst_port, :devices, :records_around
  attr_reader :verbose

  def initialize(opts)
    [ :start_time, :proto, :src_host, :src_port, :dst_host, :dst_port ].each do |k|
      raise("Need option key: #{k.inspect}") unless opts.has_key?(k)
    end

    if opts[:bpf_filter]
      puts "Using bpf filter from option. (#{@pcap_filter})" if $DEBUG
      @pcap_filter = opts[:bpf_filter]
    else
      @proto = verified_protocol(opts[:proto]) if opts[:proto]
      @src_host = verified_ipv4(opts[:src_host])
      @dst_host = verified_ipv4(opts[:dst_host])
      @src_port = verified_port(opts[:src_port]) if opts[:src_port]
      @dst_port = verified_port(opts[:dst_port]) if opts[:dst_port]
    end
    @start_time = verified_time(opts[:start_time]).to_i
    @devices = opts[:devices]
    @records_around = opts[:records_around].to_i
    @verbose = $DEBUG || !!opts[:verbose]
  end

  def pcap_filter
    return @pcap_filter if @pcap_filter
    @pcap_filter = ""
    @pcap_filter += "ip proto #{proto} and " if proto
    @pcap_filter += sprintf("host (%s and %s)", src_host, dst_host)
    ports = []
    ports << src_port if src_port
    ports << dst_port if dst_port
    @pcap_filter += sprintf(" and port (#{ports.join(' and ')})") unless ports.empty?
    return @pcap_filter
  end

  def session_find
    return @sessions if defined? @sessions
    argus_files = records.collect{|r| r.argus_file}
    @sessions = ra(argus_files)
  end

  def carve_session(tmp_dir, output_file)
    tmp_dir = Dir.mktmpdir('pcaper_', tmp_dir)
    pcaps_processed = []
    part_files = []
    session_find.each do |sess|
      records_for_session = records_within(sess[:stime], sess[:ltime])
      puts "SQL: #{records_for_session.sql.inspect}" if $DEBUG
      records_for_session.each_with_index do |rec, i|
        next if pcaps_processed.include?(rec[:filename])
        next if ra([rec[:argus_file]], ext_ra).empty?
        part_file = File.join(tmp_dir, %{part_#{Time.now.to_f}})
        cmd = %{#{ext_tcpdump} -w #{part_file} -nr #{rec[:filename]} '#{pcap_filter}'}
        puts cmd if verbose
        if system(cmd)
          part_files << part_file
        else
          raise "'#{cmd}' failed!"
        end
        pcaps_processed << rec[:filename]
      end
    end
    if part_files.empty?
      raise "No part files were produced! This must be a bug!"
    else
      cmd = %{#{ext_mergecap} -w #{output_file} #{part_files.join(" ")}}
      puts cmd if verbose
      if system(cmd)
        FileUtils.rm_rf(tmp_dir, :verbose => $DEBUG || verbose)
      else
        raise "'#{cmd}' failed! (leaving tmpdir '#{tmp_dir}' untouched)"
      end
    end
  end

  def records_found?
    !records.first.nil?
  end

  def query_start
    records.first.start_time
  end

  def query_end
    records.last.end_time
  end

  private
    def records
      return @records if @records
      @records = precise_match
      if !@records.empty? && records_around > 0
        @records += records_before(records_around) - precise_match
        @records += records_after(records_around) - precise_match
      end
      @records = @records.sort{|a,b| a.start_time <=> b.start_time}
    end

    def create_hash(headers, row)
      headers.zip(row).inject(Hash.new){|h,(k,v)| h.merge(k.to_sym=>v)}
    end

    def precise_match
      device_scope.
        where("start_time <= ? AND end_time >= ?", start_time, start_time).
        select(:id, :start_time, :end_time, :filename, :argus_file).
        order(:start_time).
        collect do |rec|
          rec 
        end
    end

    def records_before(limit)
      device_scope.
        where("start_time < ?", start_time).
        select(:id, :start_time, :end_time, :filename, :argus_file).
        order(:start_time.desc).
        limit(limit+1).
        collect do |rec|
          rec 
        end
    end

    def records_after(limit)
      device_scope.
        where("start_time > ?", start_time).
        select(:id, :start_time, :end_time, :filename, :argus_file).
        order(:start_time).
        limit(limit).
        collect do |rec|
          rec 
        end
    end

    def records_within(stime, ltime)
      device_scope.
        select(:id, :start_time, :end_time, :filename, :argus_file).
        where("end_time >= ? AND start_time <= ?", stime, ltime).
        order(:start_time)
    end

    def device_scope
      if devices
        Pcaper::Models::Pcap.where(:device => devices)
      else
        Pcaper::Models::Pcap
      end
    end

    def ra(argus_files, racmd = ext_racluster)
      columns = "stime,ltime,state,proto,saddr,sport,daddr,dport,bytes,pkts,suser,duser"
      cmd = %{#{racmd} -F #{rarc_file} -c, -M printer=encode64 -nnnuzs #{columns} -r \\\n}
      argus_files.each do |argus_file|
        cmd += %{ #{argus_file} \\\n}
      end
      cmd += %{ - '#{pcap_filter}'}
      puts cmd if $DEBUG
      rows = `#{cmd}`.split("\n").collect{|line| create_hash(columns.split(","), line.split(","))}
      puts rows.inspect if $DEBUG
      rows
    end

    def rarc_file
      File.expand_path(File.join(File.dirname(__FILE__), '.rarc'))
    end

end
