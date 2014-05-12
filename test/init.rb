require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/pride'
require 'fileutils'
require 'pp'

def pcaper_home
  @pcaper_home ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
end

def fixture_join(*path)
  File.join(pcaper_home, 'test', 'fixtures', *path)
end

TESTBED_CONFIG = {
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

def create_pcaps_db
  create_table = File.read(File.join(pcaper_home, 'db', '_pcaps.db.dump'))
  insert = File.read(fixture_join('skel', 'pcaps.db.sql')).gsub(/__PCAPER_HOME__/, pcaper_home)
  FileUtils.rm_f(TESTBED_CONFIG[:db]) if File.exist?(TESTBED_CONFIG[:db])  
  File.popen("sqlite3 #{TESTBED_CONFIG[:db]}", 'w') do |sqlite|
    sqlite.write(create_table)
    sqlite.write(insert)
  end
end
create_pcaps_db

module Pcaper
  CONFIG_FILE = :skip
  CONFIG = TESTBED_CONFIG
end

require_relative '../lib/pcaper'

