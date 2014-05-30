require_relative 'init'
require 'stringio'
require 'fileutils'

def num_rows_in_db_where_argus_file_is_null
  sql = %{select count(*) from pcaps where argus_file is null}
  rows = `sqlite3 #{fixture_join('pcaps.db')} '#{sql}'`.chomp.to_i
  unless $?.success?
    raise "sqlite3 command failed!"
  end
  return rows
end

class TestProgramGenerateArgus < MiniTest::Unit::TestCase
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
    create_pcaps_db(fixture_join('skel/pcaps_imported.sql'))
    assert_equal 2, num_rows_in_db_where_argus_file_is_null
    program = File.join(pcaper_home, 'bin/generate_argus.rb')
    dest_dir = File.join(@fixture_tmpdir, 'argus')
    FileUtils.rm_rf(dest_dir)
    opts = "-A '-U 10' -d #{dest_dir}"
    cmd = "#{program} #{opts}" # >/dev/null 2>&1"
    system(cmd)
    assert_equal 0, num_rows_in_db_where_argus_file_is_null
  ensure
    ENV['PCAPER_CONF'] = nil 
    FileUtils.rm_rf(dest_dir)
  end

end

