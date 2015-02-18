require_relative 'init'
require 'stringio'
require 'fileutils'

def num_rows_in_db
  rows = `sqlite3 #{TESTBED_CONFIG[:db]} 'select count(*) from pcaps'`.chomp.to_i
  unless $?.success?
    raise "sqlite3 command failed!"
  end
  return rows
end

class TestProgramImportPcaps < Minitest::Test
  def setup
    @fixture_tmpdir = fixture_join('tmp')
    @config_file = create_config_file
  end

  def test_program_import_pcaps
    ENV['PCAPER_CONF'] = @config_file
    create_pcaps_db(nil)
    assert_equal 0, num_rows_in_db
    program = File.join(pcaper_home, 'bin/import_pcaps.rb')
    opts = ""
    pcap_dir = fixture_join('pcaps')
    cmd = "#{program} #{opts} #{pcap_dir}" # >/dev/null 2>&1"
    system(cmd)
    assert_equal 11, num_rows_in_db
  ensure
    ENV['PCAPER_CONF'] = nil 
  end

  def test_program_import_pcaps_from_stdin
    ENV['PCAPER_CONF'] = @config_file
    create_pcaps_db(nil)
    assert_equal 0, num_rows_in_db
    program = File.join(pcaper_home, 'bin/import_pcaps.rb')
    opts = ""
    pcap_dir = fixture_join('pcaps')
    cmd = "find #{pcap_dir} -type f -name '*.pcap' | #{program} #{opts} -" # >/dev/null 2>&1"
    system(cmd)
    assert_equal 11, num_rows_in_db
  ensure
    ENV['PCAPER_CONF'] = nil 
  end

end

