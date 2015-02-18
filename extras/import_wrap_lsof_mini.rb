#!/usr/bin/env ruby
#
# This script will use lsof_mini to better handle open pcaps
# when running as an unprivileged user.
#
# lsof_mini needs to be SUID root and make sure its only
# executable for the importing user.
#

@pcap_dir        = ARGV[0]
@import_pcaps    = "/usr/local/pcaper/bin/import_pcaps.rb -nv"
@pcap_dstdir     = "/opt/pcap/%Y/%m/%d"
@logfile         = "/var/log/import_pcaps.log"
@generate_argus  = "/usr/local/pcaper/bin/generate_argus.rb -nv"
@lsof_mini       = "/etc/pcaper/bin/lsof_mini"

def runcmd(cmd)
  puts cmd
  # system(cmd)
end

def closed_pcaps
  all_pcaps = Dir.glob(@pcap_dir + "/*.pcap")
  open_pcaps = `#{@lsof_mini} #{@pcap_dir}`.split("\n")
  (all_pcaps - open_pcaps).join("\n")
end

runcmd %{echo #{closed_pcaps} | #{@import_pcaps} -d #{@pcap_dstdir} - > #{@logfile}}
runcmd %{#{@generate_argus} >> #{@logfile}}
