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
      :proto      => params['proto'],
      :src_host   => params['src'],
      :src_port   => params['sport'],
      :dst_host   => params['dst'],
      :dst_port   => params['dport'],
      :records_around => params['records_around'] || 5,
    )
  end

end

