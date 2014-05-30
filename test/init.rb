require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/pride'
require 'fileutils'
require 'tempfile'
require 'digest'
require 'pp'

def pcaper_home
  @pcaper_home ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
end

def fixture_join(*path)
  File.join(pcaper_home, 'test', 'fixtures', *path)
end

TESTBED_CONFIG = {
  :config_ver   => 1,
  :db           =>fixture_join('pcaps.db'),
  :directories  => {
    :argus  => fixture_join('argus/{device}/%Y/%m/%d'),
  },
  :web=>{
    :web_db         => fixture_join('web.db'),
    :web_carve_dir  => fixture_join('webcarve'),
    :standalone_web_workers=>false
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

TESTBED_CONFIG_OLD = {
  :db             => fixture_join('pcaps.db'),
  :argusdir       => fixture_join('argus/{device}/%Y/%m/%d'),
  :web_db         => fixture_join('web.db'),
  :web_carve_dir  => fixture_join('webcarve'),
  :standalone_web_workers => false,
  :tcpdump        => fixture_join('bin/tcpdump'),
  :mergecap       => fixture_join('bin/mergecap'),
  :ra             => fixture_join('bin/ra'),
  :racluster      => fixture_join('bin/racluster'),
  :lsof           => fixture_join('bin/lsof'),
  :capinfos       => fixture_join('bin/capinfos'),
  :argus          => fixture_join('bin/argus'),
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
  # need to reload Sequel after db file changed
  Pcaper::DB.disconnect
  Pcaper::DB.connect(TESTBED_CONFIG[:db])
  Pcaper::Models::Pcap.set_dataset(Pcaper::DB[:pcaps])
end

def capture_output(io=STDERR)
  backup_io = io.dup
  output = ""
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

module Pcaper
  CONFIG_FILE = :skip
  CONFIG = TESTBED_CONFIG
end

require_relative '../lib/pcaper'

