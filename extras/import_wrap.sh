#!/bin/bash

/usr/local/pcaper/bin/import_pcaps.rb -v -d /opt/pcap/%Y/%m/%d /opt/pcap/ > /var/log/import_pcaps.log 2>&1
/usr/local/pcaper/bin/generate_argus.rb -v >> /var/log/import_pcaps.log 2>&1
