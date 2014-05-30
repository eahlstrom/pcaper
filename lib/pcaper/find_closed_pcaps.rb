class Pcaper::FindClosedPcaps
  extend Pcaper::ExternalCommands

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
      return @open_pcap_inodes if @open_pcap_inodes
      if Process.uid == 0
        return open_pcap_inodes_lsof
      else
        return open_pcap_inodes_filestat
      end
    end

    def open_pcap_inodes_lsof
      @open_pcap_inodes ||= File.popen("#{ext_lsof} -F +d #{dir}").collect do |line|
        $1.to_i if line =~ /^i(\d+)/
      end.compact
    end

    def open_pcap_inodes_filestat
      return @open_pcap_inodes if @open_pcap_inodes
      open_files = Dir.glob(File.join(dir, file_glob)).find_all do |file|
        stat = File.stat(file)
        stat.file? && (stat.mtime.to_i >= (Time.now.to_i - 120))
      end
      return @open_pcap_inodes = open_files.collect{|f| File.stat(f).ino}
    end

end

