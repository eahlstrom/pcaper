gem 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/pride'
require 'fileutils'
require 'tempfile'
require 'digest'
require 'debugger'
require 'pp'

def pcaper_home
  @pcaper_home ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
end

def fixture_join(*path)
  File.join(pcaper_home, 'test', 'fixtures', *path)
end

TESTBED_CONFIG = {
  :config_ver   => 1,
  :db           => fixture_join('tmp/pcaps.db'),
  :directories  => {
    :argus  => fixture_join('argus/{device}/%Y/%m/%d'),
  },
  :web => {
    :db                 => fixture_join('tmp/web.db'),
    :carve_dir          => fixture_join('tmp/webcarve'),
    :standalone_worker  => true,
  },
  :commands=> {
    :tcpdump    => fixture_join('bin/tcpdump'),
    :mergecap   => fixture_join('bin/mergecap'),
    :ra         => fixture_join('bin/ra'),
    :racluster  => fixture_join('bin/racluster'),
    :lsof       => fixture_join('bin/lsof'),
    :capinfos   => fixture_join('bin/capinfos'),
    :argus      => fixture_join('bin/argus'),
  },
  :command_options=>{
    :argus    => nil,
    :mergecap => '-F pcap',
  }
}

def create_pcaps_db(insert_file)
  create_table = File.read(File.join(pcaper_home, 'db', '_pcaps.db.dump'))
  if insert_file
    insert = File.read(insert_file).gsub(/__PCAPER_HOME__/, pcaper_home)
  end
  FileUtils.rm_f(TESTBED_CONFIG[:db]) if File.exist?(TESTBED_CONFIG[:db])  
  File.popen("sqlite3 #{TESTBED_CONFIG[:db]}", 'w') do |sqlite|
    sqlite.write(create_table)
    sqlite.write(insert) if insert_file
  end
  Pcaper::Config.reload_db if Pcaper::Config.loaded?
end

def create_web_db(insert_file=nil)
  create_table = File.read(File.join(pcaper_home, 'web/db/_web.db.dump'))
  if insert_file
    insert = File.read(insert_file).gsub(/__PCAPER_HOME__/, pcaper_home)
  end
  FileUtils.rm_f(TESTBED_CONFIG[:web][:db]) if File.exist?(TESTBED_CONFIG[:web][:db])
  File.popen("sqlite3 #{TESTBED_CONFIG[:web][:db]}", 'w') do |sqlite|
    sqlite.write(create_table)
    sqlite.write(insert) if insert_file
  end
  Pcaper::Config.reload_webdb if Pcaper::Config.loaded?
end

def create_config_file
  config_file = File.join(fixture_join('tmp'), 'config.yml')
  dir = File.dirname(config_file)
  FileUtils.mkdir_p(dir) unless File.exist?(dir)
  File.open(config_file, 'w'){|fh| fh.print(TESTBED_CONFIG.to_yaml)}
  return config_file
end

def capture_output(io=STDERR)
  backup_io = io.dup
  begin
    Tempfile.open("captured_stderr") do |f|
      io.reopen(f)
      yield
      f.rewind
      f.read
    end
  ensure
    io.reopen backup_io
  end
end

require_relative '../lib/pcaper/config'
Pcaper::Config.load_hash(TESTBED_CONFIG)
require_relative '../lib/pcaper'

