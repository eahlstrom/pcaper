module Pcaper::Helpers
  def verified_time(str)
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
end
