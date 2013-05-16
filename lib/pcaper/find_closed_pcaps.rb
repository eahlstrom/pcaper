class Pcaper::FindClosedPcaps

  attr_accessor :dir, :file_glob

  def initialize(dir=".", file_glob='*.pcap')
    @dir = dir
    @file_glob = file_glob
  end
  
  def pcaps
    @pcaps ||= Dir.glob(File.join(dir, file_glob)).find_all do |file|
      stat = File.stat(file)
      stat.file? && !open_pcap_inodes.include?(stat.ino)
    end.sort{|a,b| File.stat(a).mtime <=> File.stat(b).mtime}
  end

  def self.files(dir, file_glob='*.pcap')
    f = self.new(dir, file_glob)
    f.pcaps.each do |pcap_file|
      yield pcap_file
    end
  end

  private
    def open_pcap_inodes
      @open_pcap_inodes ||= File.popen("#{Pcaper::CONFIG[:lsof]} -F +d #{dir}").collect do |line|
        $1.to_i if line =~ /^i(\d+)/
      end.compact
    end

end

