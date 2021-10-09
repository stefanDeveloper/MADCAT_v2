#!/bin/bash
if ! [ "$(id -u)" = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi

#Set iptables rules for TCP- and UDP-Modules
# iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 1:65534 -j DNAT --to 192.168.2.71:65535
# iptables -I OUTPUT -p icmp --icmp-type destination-unreachable -j DROP

# Start Enrichment Processor, piping results to /data/portmonitor.log
/usr/bin/python3 /opt/portmonitor/enrichment_processor.py /etc/madcat/config.lua  2>>/data/error.enrichment.log 1>>/data/portmonitor.log &
# Give Enrichment Processor time to start up and open /tmp/logs.erm as configured
sleep 1

# Start UDP-, ICMP-, RAW-Module, let them pipe results to Enrichment Processor FIFO.
/opt/portmonitor/udp_ip_port_mon /etc/madcat/config.lua 2>>/data/error.udp.log 1>>/tmp/logs.erm & sleep 1
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start udp_ip_port_mon: $status"
  exit $status
fi
# Start ICMP-Module
/opt/portmonitor/icmp_mon /etc/madcat/config.lua 2>>/data/error.icmp.log 1>>/tmp/logs.erm & sleep 1
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start icmp_mon: $status"
  exit $status
fi
# Start RAW-Module
/opt/portmonitor/raw_mon /etc/madcat/config.lua 2>>/data/error.raw.log 1>>/tmp/logs.erm & sleep 1
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start raw_mon: $status"
  exit $status
fi

# Start TCP-Module
/opt/portmonitor/tcp_ip_port_mon /etc/madcat/config.lua 2>>/data/error.tcp.log 1>>/dev/null & sleep 1
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start tcp_ip_port_mon: $status"
  exit $status
fi

# Change file permission, currently a workaround!
chown -R user:user /data/ipm
chown -R user:user /data/tpm
chown -R user:user /data/upm

# Give TCP-Module some time to start up and open configured FIFOs /madcat/confifo.tpm and /madcat/hdrfifo.tpm
# Start TCP Postprocessor, let it pipe results to Enrichment Processor FIFO.
/usr/bin/python3 /opt/portmonitor/tcp_ip_port_mon_postprocessor.py /etc/madcat/config.lua 2>>/data/error.tcppost.log 1>>/tmp/logs.erm &
/usr/bin/python3 /opt/portmonitor/monitoring/monitoring.py