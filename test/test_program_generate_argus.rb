require_relative 'init'
require 'stringio'
require 'fileutils'

def num_rows_in_db_where_argus_file_is_null
  sql = %{select count(*) from pcaps where argus_file is null}
  rows = `sqlite3 #{TESTBED_CONFIG[:db]} '#{sql}'`.chomp.to_i
  unless $?.success?
    raise "sqlite3 command failed!"
  end
  return rows
end

class TestProgramGenerateArgus < Minitest::Test
  def setup
    @fixture_tmpdir = fixture_join('tmp')
    @config_file = create_config_file
  end

  def test_program_generate_argus
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
    ENV['PCAPER_CONF'] = nil 
    FileUtils.rm_rf(dest_dir) if File.exist?(dest_dir)
  end

end

