class Pcaper::Config
  class << self

    attr_reader :version
    attr_reader :db

    def load(config_hash)
      verify_config_layout(config_hash)
      @c = config_hash
      @version = @c[:config_ver]
      @db = @c[:db]
    end

    def load_yaml_file(file)
      load(YAML::load(File.read(file)))
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

  end
end
