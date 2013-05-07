require 'digest'

module WebHelpers

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def human_time(usec)
      Time.at(usec.to_i).strftime("%Y-%m-%d %T")
  end

  def carver_for_params(params)
    Pcaper::Carve.new(
      :start_time => params['start_time'],
      :proto      => params['proto'].to_s.empty? ? nil : params['proto'],
      :src_host   => params['src'],
      :src_port   => params['sport'].to_s.empty? ? nil : params['sport'],
      :dst_host   => params['dst'],
      :dst_port   => params['dport'].to_s.empty? ? nil : params['dport'],
      :records_around => params['records_around'] || 5,
    )
  end

  def url_serialize(sess)
    sprintf("start_time=%s&records_around=%s&proto=%s&src=%s&sport=%s&dst=%s&dport=%s", sess[:stime], params[:records_around], sess[:proto], sess[:saddr], sess[:sport], sess[:daddr], sess[:dport])
  end

end

