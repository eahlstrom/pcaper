module Pcaper::ExternalCommands

  def method_missing(method, *args, &block)
    if method.to_s =~ /^ext_/
      return command_and_args_for(method.to_s.sub(/^ext_/,'').to_sym)
    else
      super
    end
  end

  def command_and_args_for(cmdkey)
    if Pcaper::CONFIG.has_key?(:config_ver) && Pcaper::CONFIG[:config_ver].to_f == 1.0
      command = [Pcaper::CONFIG[:commands][cmdkey], args_for(cmdkey)].compact.join(' ')
    else
      command = Pcaper::CONFIG[cmdkey]
    end
    if command.to_s.strip.empty?
      raise "failed to resolve external command: '#{cmdkey}'"
    end
    return command
  end

  def args_for(cmdkey)
    Pcaper::CONFIG[:command_options][cmdkey]
  end

end
