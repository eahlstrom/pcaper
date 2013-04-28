module Pcaper::Helpers
  def verified_time(str)
    case str
    when /\A(\d{10})\Z/
      return str.to_i
    else
      return Time.parse(str)
    end
  end
end
