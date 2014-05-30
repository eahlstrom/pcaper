require_relative 'init'
require 'stringio'
require 'fileutils'
require 'yaml'

class TestConfig < MiniTest::Unit::TestCase

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
        :standalone => false,
      },
      :commands=> {
        :tcpdump    => 'bin/tcpdump',
      },
      :command_options=>{
        :tcpdump => 'tcpdump_opts',
      }
    }
    Pcaper::Config.load(@tc)
  end

  def test_it_should_verify_config_layout
    @tc.keys.each do |config_key|
      tc = @tc.dup
      tc.delete(config_key)
      assert_raises(ArgumentError, "config without '#{config_key.inspect}' key") { Pcaper::Config.load(tc) }
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
    assert_equal @tc[:config_ver], Pcaper::Config.version
  end

  def test_it_has_db
    assert_equal @tc[:db], Pcaper::Config.db
  end

  def test_it_has_argus_dir
    assert_equal @tc[:directories][:argus], Pcaper::Config.argus_dir
  end

  def test_it_autoresolves_dirs
    assert_equal @tc[:directories][:rlsdk2], Pcaper::Config.rlsdk2_dir
  end

  def test_it_autoresolves_web_parameters
    assert_equal @tc[:web][:db], Pcaper::Config.web_db
    assert_equal @tc[:web][:carve_dir], Pcaper::Config.web_carve_dir
    assert_equal @tc[:web][:standalone], Pcaper::Config.web_standalone
  end

  def test_it_autoresolves_commands_with_params
    assert_equal 'bin/tcpdump tcpdump_opts', Pcaper::Config.command_tcpdump
  end

end

