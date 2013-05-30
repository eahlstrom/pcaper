#!/usr/bin/env ruby

if ARGV.empty?
  puts "Usage: reclaim_check.rb mount_point high_watermark_avail_kilobytes reclaim_size [reclaim_extra_opts]"
  puts "example: reclaim_check.rb /opt/pcap/ 1048576 1GB -nvA"
  exit(1)
end

mount_point, high_kb, reclaim_size = ARGV[0..2]
reclaim_opts = ARGV[3..-1].join(" ")
portable_df_output = `/bin/df -P #{mount_point}`
blocks,used,avail,utilized = portable_df_output.scan(/(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%/).flatten.collect{|v| v.to_i}

if avail <= high_kb.to_i
  reclaim = File.join(File.dirname($0), 'reclaim.rb')
  cmd = %{#{reclaim} #{reclaim_opts} #{reclaim_size}}
  puts cmd if $DEBUG
  system(cmd)
end

