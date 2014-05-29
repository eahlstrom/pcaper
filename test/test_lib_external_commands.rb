require_relative 'init'


class TestExternalCommands < MiniTest::Unit::TestCase

  def test_racluster_ip_and_ports
    columns = %{stime,ltime,state,proto,saddr,sport,daddr,dport,bytes,pkts}
    argus_file = fixture_join('argus/dump_00003_20131201111526.pcap.argus')
    rarc = "#{pcaper_home}/lib/pcaper/.rarc"
    cmd = %{#{Pcaper::CONFIG[:racluster]} -F #{rarc} -c, -M printer=encode64 -nnnuzs #{columns} -r #{argus_file}}
    assert_equal "1385892926,1385892928,E,tcp,192.168.0.1,35594,192.168.0.2,22,916,10\n", `#{cmd}`
  end

  def test_racluster_suser_encode64_printer
    columns = %{suser}
    argus_file = fixture_join('argus/dump_00003_20131201111526.pcap.argus')
    rarc = "#{pcaper_home}/lib/pcaper/.rarc"
    cmd = %{#{Pcaper::CONFIG[:racluster]} -F #{rarc} -c, -M printer=encode64 -nnnuzs #{columns} -r #{argus_file}}
    assert_equal "s[136]=AAAADAoVAAAAAAAAAAAAAA87aPXyZTwbmGSH3n4y2zJj3WjwQe8QZ+1UjKNICe5m8WESiDnPpEEal8EVQE54KdCZCc1uqRVY6LthWYxxotTSwRfhvk5sJqrIYLq+hxmD6NUSag==\n", `#{cmd}`
  end

  def test_racluster_full
    columns = %{stime,ltime,state,proto,saddr,sport,daddr,dport,bytes,pkts,suser,duser}
    argus_file = fixture_join('argus/dump_00003_20131201111526.pcap.argus')
    rarc = "#{pcaper_home}/lib/pcaper/.rarc"
    cmd = %{#{Pcaper::CONFIG[:racluster]} -F #{rarc} -c, -M printer=encode64 -nnnuzs #{columns} -r #{argus_file}}
    assert_equal "1385892926,1385892928,E,tcp,192.168.0.1,35594,192.168.0.2,22,916,10,s[136]=AAAADAoVAAAAAAAAAAAAAA87aPXyZTwbmGSH3n4y2zJj3WjwQe8QZ+1UjKNICe5m8WESiDnPpEEal8EVQE54KdCZCc1uqRVY6LthWYxxotTSwRfhvk5sJqrIYLq+hxmD6NUSag==,d[136]=P1ui8BLitizlXZhLbgTGC6mjM0NsFKBXc/N/698HCvN3qS8s1IVPEhmi5JpjFC2koREx8FlxoEpVRdBptmaK1B7CKE5c8PpROt9jqKiX2apICrqMyN5kQWD9T80Cvxm4bEWGxw==\n", `#{cmd}`
  end

end

