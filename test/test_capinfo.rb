require_relative 'init'

R = {
  :filename     => fixture_join('pcaps', 'dump_00003_20131201111526.pcap'),
  :snaplen      => 65535,
  :num_packets  => 10,
  :filesize     => 1100,
  :duration     => 1.571471,
  :start_time   => 1385892926,
  :end_time     => 1385892928,
  :bps          => 582.89,
  :pps          => 6.36,
  :sha1sum      => 'e7cb223720330717f8868a26b041ef5f6323adbd'
}


class TestCapinfo < MiniTest::Unit::TestCase

  def test_it_has_correct_filename
    inf = Pcaper::Capinfo.capinfo(R[:filename])
    assert_equal R[:filename], inf[:filename]
  end

  def test_it_has_correct_sha1sum
    inf = Pcaper::Capinfo.capinfo(R[:filename])
    assert_equal R[:sha1sum], inf[:sha1sum]
  end

  def test_all_integer_values
    inf = Pcaper::Capinfo.capinfo(R[:filename])
    [:snaplen, :num_packets, :filesize, :start_time, :end_time].each do |key|
      assert_equal R[key], inf[key]
    end
  end

  def test_all_float_values
    inf = Pcaper::Capinfo.capinfo(R[:filename])
    [:duration, :bps, :pps].each do |key|
      assert_equal R[key], inf[key]
    end
  end

end

