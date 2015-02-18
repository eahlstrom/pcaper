require_relative 'init'
require 'stringio'
require 'fileutils'
require 'yaml'

class TestConfig < Minitest::Test

  def setup
    @tc = {
      :config_ver   => 1,
      :db           => 'tmp/pcaps.db',
      :directories  => {
        :argus  => 'argus/{device}/%Y/%m/%d',
        :rlsdk2 => '/bladiyadi',
      },
      :web=>{
        :db         => 'web.db',
        :carve_dir  => 'webcarve',
        :standalone_worker => false,
      },
      :commands=> {
        :tcpdump    => 'bin/tcpdump',
      },
      :command_options=>{
        :tcpdump => 'tcpdump_opts',
      }
    }
    Pcaper::Config.unload_config!
  end

  def test_it_should_verify_config_layout
    @tc.keys.each do |config_key|
      tc = @tc.dup
      tc.delete(config_key)
      assert_raises(ArgumentError, "config without '#{config_key.inspect}' key") { Pcaper::Config.load_hash(tc) }
    end
  end

  def test_it_should_load_yaml_file
    tc = @tc.dup
    tc[:config_ver] = 'from file'
    config_file = fixture_join('tmp/test_config.yml')
    File.open(config_file, 'w'){|fh| fh.print tc.to_yaml}
    Pcaper::Config.load_yaml_file(config_file)
    assert_equal 'from file', Pcaper::Config.version
    FileUtils.rm_f(config_file)
  end

  def test_it_has_version
    Pcaper::Config.load_hash(@tc)
    assert_equal @tc[:config_ver], Pcaper::Config.version
  end

  def test_it_has_db_initialized
    Pcaper::Config.load_hash(@tc)
    assert_equal Sequel::SQLite::Database, Pcaper::Config.db.class
  end

  def test_it_has_db_as_the_correct_file
    Pcaper::Config.load_hash(@tc)
    assert_equal @tc[:db], Pcaper::Config.dbfile
  end

  def test_it_has_argus_dir
    Pcaper::Config.load_hash(@tc)
    assert_equal @tc[:directories][:argus], Pcaper::Config.argus_dir
  end

  def test_it_autoresolves_dirs
    Pcaper::Config.load_hash(@tc)
    assert_equal @tc[:directories][:rlsdk2], Pcaper::Config.rlsdk2_dir
  end

  def test_it_autoresolves_web_parameters
    Pcaper::Config.load_hash(@tc)
    assert_equal @tc[:web][:db], Pcaper::Config.web_db
    assert_equal @tc[:web][:carve_dir], Pcaper::Config.web_carve_dir
    assert_equal @tc[:web][:standalone_worker], Pcaper::Config.web_standalone_worker
  end

  def test_it_autoresolves_commands_with_params
    Pcaper::Config.load_hash(@tc)
    assert_equal 'bin/tcpdump tcpdump_opts', Pcaper::Config.command_tcpdump
  end

  def test_it_should_return_nil_for_an_empty_sub_option
    Pcaper::Config.load_hash(@tc)
    assert_nil Pcaper::Config.web_none_existing_key
  end

  def test_it_should_unload_config
    Pcaper::Config.load_hash(@tc)
    assert Pcaper::Config.loaded?
    Pcaper::Config.unload_config!
    refute Pcaper::Config.loaded?
  end

  def test_if_its_loaded
    refute Pcaper::Config.loaded?
    Pcaper::Config.load_hash(@tc)
    assert Pcaper::Config.loaded?
  end

  def test_it_has_webdb_initialized
    Pcaper::Config.load_hash(@tc)
    assert_equal Sequel::SQLite::Database, Pcaper::Config.webdb.class
  end

  def test_it_has_webdb_as_the_correct_file
    Pcaper::Config.load_hash(@tc)
    assert_equal @tc[:web][:db], Pcaper::Config.webdbfile
  end

  def test_it_has_web_carvedir
    Pcaper::Config.load_hash(@tc)
    assert_equal @tc[:web][:carve_dir], Pcaper::Config.web_carve_dir
  end

end

