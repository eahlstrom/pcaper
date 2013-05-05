require 'json'
require 'zlib'

class CarveDatabase
  attr_reader :carve, :params

  def initialize(params = nil)
    @carve = Pcaper::WEBDB[:carve]
    @params = params
  end

  def working_on_params?
    !!carve.where(:chksum => chksum).first
  end

  def add
    carve.insert(
      :chksum       => chksum,
      :submitted     => Time.now.to_i,
      :local_file   => File.join(Pcaper::CONFIG[:webfilesdir], chksum.to_s + '.pcap'),
      :params       => params.to_json,
      :worker_state => 'submitted',
    )
  end

  def worker_state
    row[:worker_state]
  end

  def worker_msg
    row[:worker_msg]
  end

  def submitted
    row[:submitted]
  end

  def finished
    row[:finished]
  end

  def local_file
    row[:local_file]
  end

  private
    def row
      @row ||= carve.where(:chksum => chksum).first
    end

    def chksum
      keys = %w{ start_time proto src sport dst dport records_around }
      Zlib.crc32((params.find_all{|k,v| keys.include?(k)}).join)
    end

end
