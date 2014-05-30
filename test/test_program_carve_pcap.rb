require_relative 'init'
require 'stringio'
require 'fileutils'


class TestProgramCarvePcap < MiniTest::Unit::TestCase
  def setup
    create_pcaps_db(fixture_join('skel/fully_populated.sql'))
    @fixture_tmpdir = fixture_join('tmp')
    unless defined? @config_file
      @config_file = File.join(@fixture_tmpdir, 'config.yml')
      FileUtils.mkdir_p(@fixture_tmpdir) unless File.exist?(@fixture_tmpdir)
      unless File.exist?(@config_file)
        File.open(@config_file, 'w'){|fh| fh.print(TESTBED_CONFIG.to_yaml)}
      end
    end
  end

  def test_should_carve_out_session
    ENV['PCAPER_CONF'] = @config_file
    carved_file = File.join(@fixture_tmpdir, 'carved.pcap')
    carve_pcap = %{#{pcaper_home}/bin/carve_pcap.rb}
    FileUtils.rm_f(carved_file) if File.exist?(carved_file)
    opts = %{-p tcp -S 192.168.0.1 -s 35594 -D 192.168.0.2 -d 22 -A 0 -t #{@fixture_tmpdir} -w #{carved_file} 2013-12-01 11:15:26 +0100}
    cmd = "echo run | #{carve_pcap} #{opts} >/dev/null 2>&1"
    system(cmd)
    pkts = `tcpdump -qnr test/fixtures/tmp/carved.pcap 2>/dev/null  | wc -l`.chomp.to_i
    assert_equal 25, pkts
    if File.exist?(carved_file) && ENV['test_dont_delete'].nil?
      FileUtils.rm_f(carved_file)
    end
    ENV['PCAPER_CONF'] = nil 
  end

end

