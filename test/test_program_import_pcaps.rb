require_relative 'init'
require 'stringio'
require 'fileutils'

def num_rows_in_db
  rows = `sqlite3 #{fixture_join('pcaps.db')} 'select count(*) from pcaps'`.chomp.to_i
  unless $?.success?
    raise "sqlite3 command failed!"
  end
  return rows
end

class TestProgramImportPcaps < MiniTest::Unit::TestCase
  def setup
    @fixture_tmpdir = fixture_join('tmp')
    unless defined? @config_file
      @config_file = File.join(@fixture_tmpdir, 'config.yml')
      FileUtils.mkdir_p(@fixture_tmpdir) unless File.exist?(@fixture_tmpdir)
      unless File.exist?(@config_file)
        File.open(@config_file, 'w'){|fh| fh.print(TESTBED_CONFIG.to_yaml)}
      end
    end
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

end

