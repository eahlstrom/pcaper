
module Pcaper::Capinfo
  extend Pcaper::ExternalCommands

  HEADER_MAP = {
    "File name"                         => :filename,
    "Packet size limit"                 => :snaplen,
    "Number of packets"                 => :num_packets,
    "File size (bytes)"                 => :filesize,
    "Capture duration (seconds)"        => :duration,
    "Start time"                        => :start_time,
    "End time"                          => :end_time,
    "Data byte rate (bytes/sec)"        => :bps,
    "Average packet rate (packets/sec)" => :pps,
    "SHA1"                              => :sha1sum,
  }

  def instantiate_value(v)
    case v
    when /^\d+$/
      v.to_i
    when /^\d+\.\d+$/
      v.to_f
    when /^\d+,\d+$/
      v.sub(/,/,'.').to_f
    when "(not set)"
      nil
    else
      v
    end
  end
  module_function :instantiate_value

  def capinfo(pcap_file)
    capinfo = {}
    headers = nil
    File.stat(pcap_file).file? || raise(Errno::ENOENT)
    File.popen("#{capinfos} -TB -HcslxyuSaeo #{pcap_file}").each_line do |line|
      line.chomp!
      unless headers
        headers = line.split("\t")
        next
      end
      headers.zip(line.split("\t")).each do |k,v|
        colname = HEADER_MAP[k]
        capinfo[colname] = instantiate_value(v) if colname
      end
    end
    return capinfo
  end
  module_function :capinfo

end
