require_relative 'init'

class TestExternalCommands < MiniTest::Unit::TestCase
  def setup
    extend Pcaper::ExternalCommands
  end

  def test_command_and_args_for_v1_without_args
    Pcaper::CONFIG[:config_ver] = 1
    Pcaper::CONFIG[:command_options].delete(:capinfos)
    assert_equal fixture_join('bin/capinfos'), capinfos
  end

  def test_command_and_args_for_v1_with_args
    Pcaper::CONFIG[:config_ver] = 1
    Pcaper::CONFIG[:command_options][:capinfos] = "-ARGS"
    assert_equal fixture_join('bin/capinfos') + " -ARGS", capinfos
  end

  def test_command_and_args_for_old_config
    Pcaper::CONFIG.delete(:config_ver)
    Pcaper::CONFIG[:capinfos] = "path_to_capinfos"
    assert_equal "path_to_capinfos", capinfos
    Pcaper::CONFIG.delete(:capinfos)
  end

end

