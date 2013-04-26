class Pcaper::Models::Pcap < Sequel::Model
  many_to_one :directory

  def self.pcap_imported?(pcap_file)
    !self.where(:sha1sum => Digest::SHA1.file(pcap_file).to_s).empty?
  end

  def self.add_capinfo(capinfo)
    dir = Pcaper::Models::Directory.find_or_create(:location => File.dirname(capinfo[:filename]))
    record = self.new(capinfo)
    record.filename = File.basename(record.filename)
    record.directory = dir
    record.save
  end
end
