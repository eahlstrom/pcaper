#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'
include FileUtils

base_data_dir = ARGV[1] || "/opt"
config_dir = ARGV[0] || "/etc/pcaper"
if File.exist?(config_dir)
  puts %{Already setup! (dir "#{config_dir}" exists)}
  exit 1
end

def runcmd(cmd)
  puts cmd
  raise("command failed") unless system(cmd)
end

def find_program(program)
  loc = `which #{program}`.chomp.strip
  unless File.exist?(loc)
    %w{ /sbin /usr/sbin /usr/local/sbin }.each do |dir|
      if File.exist?(File.join(dir, program))
        loc = File.join(dir, program)
        break
      end
    end
  end
  unless File.exist?(loc)
    print %{Program "#{program}" not found! Enter location manually: }
    loc = $stdin.gets.chomp
  end
  return loc
end

begin

  lsb = File.read("/etc/lsb-release").scan(/(\S+)=(\S+)/).inject({}) do |hsh,(k,v)|
    hsh.merge(k.upcase=>v)
  end

  if lsb['DISTRIB_ID'] =~ /Ubuntu/i
    runcmd %{apt-get install lsof wireshark-common tcpdump sqlite3}
    runcmd %{apt-get install ruby-sequel libsqlite3-ruby ruby-sinatra ruby-haml ruby-json}
  else
    raise %{Unknown DISTRIB_ID "#{lsb['DISTRIB_ID']}"}
  end

  if lsb['DISTRIB_RELEASE'] == "13.10"
    unless File.exist?('/usr/lib/x86_64-linux-gnu/ruby/2.0.0/sqlite3/sqlite3_native.so')
      puts "Bugfix for ubuntu 13.10"
      runcmd %{ln -s /usr/lib/ruby/vendor_ruby/1.9.1/x86_64-linux/sqlite3 /usr/lib/x86_64-linux-gnu/ruby/2.0.0}
    end
  end

  conf = {
    :db             => File.join(config_dir, "pcaps.db"),
    :argusdir       => File.join(base_data_dir, "argus/%Y/%m/%d"),
    :web_db         => File.join(config_dir, "web/web.db"),
    :web_carve_dir  => File.join(config_dir, "web/webcarve"),
    :standalone_web_workers => false,
  }

  [ :tcpdump, :mergecap, :ra, :racluster, :lsof, :capinfos, :argus ].each do |p|
    loc = find_program(p.to_s)
    conf[p] = loc
  end

  mkdir_p(config_dir)
  config_file = File.join(config_dir, 'config.yml')
  puts "Creating config file #{config_file}..."
  File.open(config_file, 'w') do |fh|
    fh.print conf.to_yaml
  end
  mkdir_p(File.basename(conf[:web_db]))
  mkdir_p(conf[:web_carve_dir]) unless File.exist?(conf[:web_carve_dir])
  if File.exist?("/usr/local/pcaper/db/_pcaps.db.dump")
    runcmd("sqlite3 #{conf[:db]} < /usr/local/pcaper/db/_pcaps.db.dump")
  end
  if File.exist?("/usr/local/pcaper/web/db/_web.db.dump")
    runcmd("sqlite3 #{conf[:web_db]} < /usr/local/pcaper/web/db/_web.db.dump")
  end
  
rescue => e
  puts "error: " + e.message
  exit 1
end
