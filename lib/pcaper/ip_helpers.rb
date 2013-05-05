module Pcaper::IPHelpers

  def getprotobyname(proto)
    ip_protocols[proto.downcase] || raise(ArgumentError, "Cannot resolve proto: #{proto}")
  end

  def ip_protocols
    @ip_protocols ||= File.read('/etc/protocols').
      scan(/^([a-zA-Z]{1}\S+)\s+(\d+)/).
      inject(Hash.new){|h,(k,v)| h.merge(k.downcase => v.to_i)}
  end

  def verified_protocol(proto)
    if proto.match(/\A\d+$\Z/)
      proto.to_i
    else
      getprotobyname(proto).to_i
    end
  end

  def verified_port(port)
    if valid_port?(port)
      return port
    else
      raise ArgumentError, "Invalid port: '#{port}'"
    end
  end

  def verified_ipv4(ip)
    if valid_ipv4?(ip)
      return ip
    else
      raise ArgumentError, "Invalid ipv4 address: '#{ip}'"
    end
  end

  def valid_port?(port)
    if /\A(\d+)\Z$/ =~ port
      return $~.captures.all? do |i|
        i.to_i.between?(1, 65535)
      end
    end
  end

  def valid_ipv4?(ip)
    if /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}\Z)$/ =~ ip
      return $~.captures.all? do |i|
        i.to_i.between?(0, 255)
      end
    end
  end

end
