class Pcaper::Carve
  include Pcaper::IPHelpers
  include Pcaper::Helpers

  attr_reader :start_time, :proto, :src_host, :src_port, :dst_host, :dst_port, :devices, :records_around
  attr_reader :verbose

  def initialize(opts)
    [ :start_time, :proto, :src_host, :src_port, :dst_host, :dst_port ].each do |k|
      raise("Need option key: #{k.inspect}") unless opts.has_key?(k)
    end

    @start_time = verified_time(opts[:start_time]).to_i
    @proto = verified_protocol(opts[:proto])
    @src_host = verified_ipv4(opts[:src_host])
    @src_port = verified_port(opts[:src_port])
    @dst_host = verified_ipv4(opts[:dst_host])
    @dst_port = verified_port(opts[:dst_port])
    @devices = opts[:devices]
    @records_around = opts[:records_around].to_i
    @verbose = !!opts[:verbose]
  end

  def pcap_filter
    sprintf("ip proto %d and host (%s and %s) and port (%d and %d)", 
            proto, src_host, dst_host, src_port, dst_port) 
  end

  def session_find
    argus_files = records.collect{|r| r.argus_file}
    columns = "stime,ltime,state,proto,saddr,sport,daddr,dport"
    cmd = %{racluster -F etc/rarc -c, -nnnuzs #{columns} -r #{argus_files.join(' ')} - '#{pcap_filter}'}
    puts cmd if verbose
    `#{cmd}`.split("\n").collect{|line| create_hash(columns.split(","), line.split(","))}
  end

  def carve_session_in_records
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
      if records_around > 0
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
        order(Sequel.desc :start_time).
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

    def device_scope
      if devices
        Pcaper::Models::Pcap.where(:device => devices)
      else
        Pcaper::Models::Pcap
      end
    end

end
