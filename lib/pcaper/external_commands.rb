module Pcaper::ExternalCommands

  def method_missing(*args)
    command_and_args_for(args[0])
  end

  def command_and_args_for(cmdkey)
    if Pcaper::CONFIG.has_key?(:config_ver) && Pcaper::CONFIG[:config_ver].to_f == 1.0
      command = [Pcaper::CONFIG[:commands][cmdkey], args_for(cmdkey)].compact.join(' ')
      return command
    else
      Pcaper::CONFIG[cmdkey]
    end
  end

  def args_for(cmdkey)
    Pcaper::CONFIG[:command_options][cmdkey]
  end

end
