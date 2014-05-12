require_relative 'init'

class TestPcaperInit < MiniTest::Unit::TestCase

  def test_this_testbeds_pcapdb
    assert_equal [:pcaps], Pcaper::DB.tables
  end

  def test_this_testbeds_webdb
    skip
    assert_equal [:carve], Pcaper::WEBDB.tables
  end

  def test_that_testbed_has_all_the_files_in_db
    Dir.glob(fixture_join('pcaps', '*.pcap')).each do |pcap|
      assert Pcaper::Models::Pcap.pcap_imported?(pcap)
    end
  end

  def test_that_db_has_the_correct_samples
    Dir.glob(fixture_join('pcaps', '*.pcap')).each do |pcap|
      capinfo_record = Pcaper::Capinfo.capinfo(pcap)
      db_record = Pcaper::Models::Pcap.record_for_pcap(pcap)
      capinfo_record.each_pair do |key, correct_value|
        assert_equal correct_value, db_record[key]
      end
    end
  end

end

