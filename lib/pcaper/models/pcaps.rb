class Pcaper::Models::Pcap < Sequel::Model
  def self.pcap_imported?(pcap_file)
    !self.where(:sha1sum => Digest::SHA1.file(pcap_file).to_s).empty?
  end
end
