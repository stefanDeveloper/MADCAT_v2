#!/bin/bash
#Set iptables rules for TCP- and UDP-Modules
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 1:65534 -j DNAT --to 192.168.2.71:65535
iptables -I OUTPUT -p icmp --icmp-type destination-unreachable -j DROP
# Start Enrichment Processor, piping results to /data/madcat.log
/usr/bin/python3 /opt/portmonitor/enrichment_processor.py /etc/madcat/config.lua  2>>/data/error.enrichment.log 1>>/data/madcat.log &
# Give Enrichment Processor time to start up and open /data/tmp/logs.erm as configured
sleep 1
# Start UDP-, ICMP-, RAW-Module, let them pipe results to Enrichment Processor FIFO.
/opt/portmonitor/udp_ip_port_mon /etc/madcat/config.lua 2>>/data/error.udp.log 1>>/data/tmp/logs.erm &
/opt/portmonitor/icmp_mon /etc/madcat/config.lua 2>> /data/error.icmp.log 1>>/data/tmp/logs.erm &
/opt/portmonitor/raw_mon /etc/madcat/config.lua 2>> /data/error.raw.log 1>>/data/tmp/logs.erm &
# Start TCP-Module
/opt/portmonitor/tcp_ip_port_mon /etc/madcat/config.lua 2>>/data/error.tcp.log 1>>/dev/null &
# Give TCP-Module some time to start up and open configured FIFOs /madcat/confifo.tpm and /madcat/hdrfifo.tpm
sleep 1
# Start TCP Postprocessor, let it pipe results to Enrichment Processor FIFO.
/usr/bin/python3 /opt/portmonitor/tcp_ip_port_mon_postprocessor.py /etc/madcat/config.lua 2>>/data/error.tcppost.log 1>>/data/tmp/logs.erm &
/usr/bin/python3 /opt/portmonitor/monitoring/monitoring.py