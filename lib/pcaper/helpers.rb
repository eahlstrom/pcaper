module Pcaper::Helpers
  def verified_time(str)
    t = parse_time(str)
    unless t.to_i.between?(946681200, 1893452400)
      raise ArgumentError, "epoch (#{t.to_i}): out of range"
    end
    return t
  end

  def parse_time(str)
    case str
    when /\A(\d{10})\Z/
      return str.to_i
    else
      begin
        return Time.parse(str)
      rescue => e
        raise ArgumentError, e.message
      end
    end
  end
  private :parse_time

end
