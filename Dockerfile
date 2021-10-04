FROM ubuntu:18.04 
MAINTAINER stefan-machmeier@outlook.com

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
    sudo \
    python-apt \
    python3-distutils-extra \
    python3-apt \
    telnet
    
RUN pip3 install psutil setuptools
RUN pip3 install luaparser split

RUN git clone https://github.com/stefanDeveloper/MADCAT_v2_docker.git /madcat

RUN cd /madcat && \
    cmake -B build . && \
    make

RUN cd /madcat && \
    cp -r etc/madcat /etc/ && \
    mkdir /opt/portmonitor && \
    cp scripts/run_madcat.sh /opt/portmonitor && \
    cp bin/tcp_ip_port_mon /opt/portmonitor && \
    cp bin/udp_ip_port_mon /opt/portmonitor && \
    cp bin/raw_mon /opt/portmonitor && \
    cp bin/icmp_mon /opt/portmonitor && \
    cp bin/enrichment_processor.py /opt/portmonitor && \
    cp bin/tcp_ip_port_mon_postprocessor.py /opt/portmonitor && \
    cp -r bin/monitoring /opt/portmonitor/ && \
    chmod +x /opt/portmonitor/tcp_ip_port_mon && \
    chmod +x /opt/portmonitor/udp_ip_port_mon && \
    chmod +x /opt/portmonitor/raw_mon && \
    chmod +x /opt/portmonitor/icmp_mon && \
    chmod +x /opt/portmonitor/tcp_ip_port_mon && \
    chmod +x /opt/portmonitor/enrichment_processor.py && \
    chmod +x /opt/portmonitor/monitoring/monitoring.py && \
    chmod +x /opt/portmonitor/tcp_ip_port_mon_postprocessor.py && \
    chmod +x /opt/portmonitor/run_madcat.sh 

RUN \
    groupadd -g 999 user && useradd -u 999 -g user -G sudo -m -s /bin/bash user && \
    sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' && \
    echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "Customized the sudoers file for passwordless access to the user user!" && \
    echo "user user:";  su - user -c id

USER root


RUN mkdir /var/run/madcat && \
    mkdir /data

RUN mkdir /data/tmp && \
    mkdir /data/ipm && \
    mkdir /data/upm 

CMD ["/opt/portmonitor/run_madcat.sh"]