FROM ubuntu:18.04 
MAINTAINER stefan-machmeier@outlook.com

USER root

# Setup apt
RUN apt-get update && \
    apt-get update -y && \
    apt-get dist-upgrade -y

RUN apt-get install -y \
    gcc \
    cmake \
    build-essential \
    libpcap0.8 libpcap-dev \
    liblua5.1-0 \
    liblua5.1-0-dev \
    libssl1.1 \
    libssl-dev \
    python3-dev \
    conntrack \
    auditd \
    audispd-plugins \
    audit.d \
    net-tools \
    gdb \
    pkg-config \
    strace \
    valgrind \
    python3-pip \
    iptables \
    git \
    sudo
# Apt-get update necessary
RUN apt-get update && \
    apt-get install -y \
    python3-distutils-extra \
    python3-apt \
    lsb-release \
    lsb-core \
    rsyslog \
    dnsutils
    
RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

RUN pip3 install psutil setuptools luaparser split

# RUN echo "-w /usr/bin/docker -p wa\n-w /var/lib/docker -p wa\n-w /etc/docker -p wa\n-w /lib/systemd/system/docker.service -p wa\n-w /lib/systemd/system/docker.socket -p wa\n-w /etc/default/docker -p wa\n-w /etc/docker/daemon.json -p wa\n-w /usr/bin/docker-containerd -p wa\n-w /usr/bin/docker-runc -p wa" | tee -a /etc/audit/audit.rules >/dev/null
ADD . /madcat

RUN cd /madcat && \
    cmake -B build . && \
    make

RUN cd /madcat && \
    mkdir /etc/madcat && \
    cp etc/madcat/config.lua /etc/madcat && \
    mkdir /opt/portmonitor && \
    cp scripts/run_madcat.sh /opt/portmonitor && \
    cp bin/tcp_ip_port_mon /opt/portmonitor && \
    cp bin/udp_ip_port_mon /opt/portmonitor && \
    cp bin/raw_mon /opt/portmonitor && \
    cp bin/icmp_mon /opt/portmonitor && \
    cp bin/enrichment_processor.py /opt/portmonitor && \
    cp bin/tcp_ip_port_mon_postprocessor.py /opt/portmonitor && \
    cp -r bin/monitoring /opt/portmonitor/ && \
    cp etc/madcat/monitoring_config.py /opt/portmonitor/monitoring && \
    chmod +x /opt/portmonitor/tcp_ip_port_mon && \
    chmod +x /opt/portmonitor/udp_ip_port_mon && \
    chmod +x /opt/portmonitor/raw_mon && \
    chmod +x /opt/portmonitor/icmp_mon && \
    chmod +x /opt/portmonitor/tcp_ip_port_mon && \
    chmod +x /opt/portmonitor/enrichment_processor.py && \
    chmod +x /opt/portmonitor/monitoring/monitoring.py && \
    chmod +x /opt/portmonitor/tcp_ip_port_mon_postprocessor.py && \
    chmod a+x /opt/portmonitor/run_madcat.sh 

RUN addgroup --gid 999 user
RUN adduser --system --no-create-home --uid 999 --disabled-password --disabled-login --gid 999 user

RUN mkdir /var/run/madcat && \
    mkdir /data

RUN mkdir /data/ipm && \
    mkdir /data/upm && \
    mkdir /data/tpm

USER root

CMD ["/opt/portmonitor/run_madcat.sh"]