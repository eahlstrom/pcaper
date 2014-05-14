require_relative 'init'
require 'stringio'
require 'fileutils'


class TestCarve < MiniTest::Unit::TestCase

  def test_pcap_filter_generated
    carver = Pcaper::Carve.new(
      :start_time => "2013-12-01 11:15:26 +0100",
      :proto      => 'tcp',
      :src_host   => '192.168.0.1',
      :src_port   => '35594',
      :dst_host   => '192.168.0.2',
      :dst_port   => '22',
      :records_around => 0,
      :bpf_filter => nil,
      :devices    => nil,
      :verbose    => false,
    )
    assert_equal carver.pcap_filter, "ip proto 6 and host (192.168.0.1 and 192.168.0.2) and port (35594 and 22)"
  end

  def test_should_use_raw_bfp_if_requested
    carver = Pcaper::Carve.new(
      :start_time => "2013-12-01 11:15:26 +0100",
      :proto      => 'tcp',
      :src_host   => '192.168.0.1',
      :src_port   => '35594',
      :dst_host   => '192.168.0.2',
      :dst_port   => '22',
      :records_around => 0,
      :devices    => nil,
      :verbose    => false,
      :bpf_filter => 'port 8080',
    )
    assert_equal carver.pcap_filter, "port 8080"
  end


  def test_find_session
    carver = Pcaper::Carve.new(
      :start_time => "2013-12-01 11:15:26 +0100",
      :proto      => 'tcp',
      :src_host   => '192.168.0.1',
      :src_port   => '35594',
      :dst_host   => '192.168.0.2',
      :dst_port   => '22',
      :records_around => 0,
      :bpf_filter => nil,
      :devices    => nil,
      :verbose    => false,
    )
    assert_equal carver.session_find, [{
      :stime  => "1385892926",
      :ltime  => "1385892928",
      :state  => "sSE",
      :proto  => "tcp",
      :saddr  => "192.168.0.1",
      :sport  => "35594",
      :daddr  => "192.168.0.2",
      :dport  => "22",
      :bytes  => "4682",
      :pkts   => "25",
      :suser  =>  "s[100]=SSH-2.0-OpenSSH_5.9p1 Debian-5ubuntu1.1.........._..E....he........ecdh-sha2-nistp256",
      :duser  => "ecdh-sha2-nist"
    }]
  end

  def test_find_session_by_bpf
    carver = Pcaper::Carve.new(
      :start_time => "1385892942",
      :proto      => nil,
      :src_host   => nil,
      :src_port   => nil,
      :dst_host   => nil,
      :dst_port   => nil,
      :records_around => 0,
      :bpf_filter => 'port 25',
      :devices    => nil,
      :verbose    => false,
    )
    assert_equal carver.session_find, [{
      :stime  => "1385892942",
      :ltime  => "1385892942",
      :state  => "sR",
      :proto  => "tcp",
      :saddr  => "192.168.0.1",
      :sport  => "41171",
      :daddr  => "192.168.0.2",
      :dport  => "25",
      :bytes  => "134",
      :pkts   => "2",
      :suser  => nil,
      :duser  => nil
    }]
  end

  def test_should_carve_out_session
    carver = Pcaper::Carve.new(
      :start_time => "2013-12-01 11:15:26 +0100",
      :proto      => 'tcp',
      :src_host   => '192.168.0.1',
      :src_port   => '35594',
      :dst_host   => '192.168.0.2',
      :dst_port   => '22',
      :records_around => 10,
      :bpf_filter => nil,
      :devices    => nil,
      :verbose    => false,
    )
    pcap_file = "/tmp/#{$$}.carved_session_test.pcap"
    output = capture_output do
      carver.carve_session('/tmp', pcap_file)
    end
    assert File.exist?(pcap_file)
    if File.read(pcap_file, 4).unpack("H*").first != 'd4c3b2a1'
      $stderr.puts "WARNING: generated file was not in libpcap format" # check mergecap -F
    else
      assert_equal '544c26e7c0789142099d5c410b72e569', Digest::MD5.file(pcap_file).to_s
    end
  ensure
    if File.exist?(pcap_file) && ENV['test_should_carve_out_session_debug'].nil?
      FileUtils.rm_f(pcap_file)
    end
  end

end

