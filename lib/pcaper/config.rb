begin
  require 'sequel'
rescue LoadError
  require 'rubygems'
  require 'sequel'
end
require 'yaml'

class Pcaper::Config
  class << self

    attr_reader :version, :dbfile, :db, :c

    def load
      if ENV['PCAPER_CONF']
        file = ENV['PCAPER_CONF']
      elsif File.exist?(File.join(ENV['HOME'], '.pcaper', 'config.yml'))
        file = File.join(ENV['HOME'], '.pcaper', 'config.yml')
      else File.exist?('/etc/pcaper/config.yml')
        file = '/etc/pcaper/config.yml'
      end
      unless File.exist?(file)
        $stderr.puts "No config found! searched:"
        $stderr.puts " - $PCAPER_CONF"
        $stderr.puts " - ~/.pcaper/config.yml"
        $stderr.puts " - /etc/pcaper/config.yml"
        $stderr.puts ""
        $stderr.puts "Please generate this file first or specify yours"
        $stderr.puts "with the environment variable PCAPER_CONF"
        $stderr.puts
        print_default_config
      end
      begin
        load_yaml_file(file)
      rescue ArgumentError => e
        $stderr.printf "Invalid config file: #{file} -> error: #{e.message}\n\n"
        print_default_config
      end
    end

    def load_hash(config_hash)
      unload_config! if loaded?
      verify_config_layout(config_hash)
      @c = config_hash
      @version = @c[:config_ver]
      @db = Sequel.sqlite(@c[:db])
      # Pcaper::Models::Pcap.set_dataset(@db)
    end

    def load_yaml_file(file)
      load_hash(YAML::load(File.read(file)))
    end

    def unload_config!
      if defined?(@db)
        @db.disconnect
        remove_instance_variable(:@db)
      end
      remove_instance_variable(:@c)       if defined?(@c)
      remove_instance_variable(:@version) if defined?(@version)
    end

    def loaded?
      !(version.nil? || db.nil?)
    end

    def verify_config_layout(config_hash)
      [:config_ver, :db, :directories, :web, :commands, :command_options].each do |key|
        key = key.to_sym
        unless config_hash.has_key?(key)
          raise ArgumentError, "miss key #{key.inspect}"
        end
      end
    end

    def method_missing(method, *args, &block)
      if method.to_s =~ /^web_(\S+)/
        return resolve_web($1)
      elsif method.to_s =~ /^command_(\S+)/
        return resolve_command($1)
      elsif method.to_s =~ /(\S+)_dir$/
        return resolve_dir($1)
      else
        super
      end
    end
 
    def resolve_dir(key)
      @c[:directories][key.to_sym]
    end

    def resolve_web(key)
      @c[:web][key.to_sym]
    end
    
    def resolve_command(key)
      key = key.to_sym
      cmd = @c[:commands][key]
      opts = @c[:command_options].has_key?(key) ? " #{@c[:command_options][key]}" : ''
      return cmd + opts
    end
    
    def resolve_path_for(cmd)
      r = %x{which #{cmd.to_s}}.chomp
      return r.empty? ? 'NOT FOUND!!' : r
    end

    def print_default_config
      $stderr.puts "Example of a default config:"
      $stderr.puts "---- snipp ----"
puts <<END
---
:config_ver: 1

# main database for pcaper
:db: /etc/pcaper/pcaps.db

:directories:
  :argus: /opt/{device}/argus/%Y/%m/%d

:web:
  :web_db:        /etc/pcaper/web/web.db
  :web_carve_dir: /etc/pcaper/web/webcarve
  :standalone:    false

:commands:
  :tcpdump:     #{resolve_path_for(:tcpdump)}
  :mergecap:    #{resolve_path_for(:mergecap)}
  :ra:          #{resolve_path_for(:ra)}
  :racluster:   #{resolve_path_for(:racluster)}
  :lsof:        #{resolve_path_for(:lsof)}
  :capinfos:    #{resolve_path_for(:capinfos)}
  :argus:       #{resolve_path_for(:argus)}

:command_options:
  :argus:
  :mergecap:  -F pcap
END
      $stderr.puts "---- snipp ----"
      exit 1
    end

  end
end
