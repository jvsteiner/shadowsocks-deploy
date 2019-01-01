#!/usr/bin/env bash
sudo apt update && sudo apt upgrade -yuf
sudo apt-get install -y --no-install-recommends gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libudns-dev automake libmbedtls-dev libsodium-dev git python-m2crypto libc-ares-dev
cd /opt
sudo git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
sudo git submodule update --init --recursive
sudo ./autogen.sh
sudo ./configure
sudo make && sudo make install
sudo adduser --system --no-create-home --group shadowsocks
sudo mkdir -m 755 /etc/shadowsocks
ip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

printf "{\n\
    \"server\":\"$ip\",\n\
    \"server_port\":443,\n\
    \"password\":\"holymoly\",\n\
    \"timeout\":300,\n\
    \"method\":\"aes-256-gcm\",\n\
    \"fast_open\": true\n}\n" | sudo tee /etc/shadowsocks/shadowsocks.json

sudo bash -c 'cat >/etc/sysctl.d/local.conf <<EOL
# max open files
fs.file-max = 51200
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096
# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1
# turn off fast timewait sockets recycling
net.ipv4.tcp_tw_recycle = 0
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65000
# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 4096
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
# turn on TCP Fast Open on both client and server side
net.ipv4.tcp_fastopen = 3
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1
# for high-latency network
net.ipv4.tcp_congestion_control = hybla
# for low-latency network, use cubic instead
net.ipv4.tcp_congestion_control = cubic
EOL'

sudo sysctl --system

sudo bash -c 'cat >/etc/systemd/system/shadowsocks.service <<EOL
[Unit]
Description=Shadowsocks proxy server

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/ss-server -c /etc/shadowsocks/shadowsocks.json -a shadowsocks -v start
ExecStop=/usr/local/bin/ss-server -c /etc/shadowsocks/shadowsocks.json -a shadowsocks -v stop

[Install]
WantedBy=multi-user.target
EOL'

sudo systemctl daemon-reload
sudo systemctl enable shadowsocks
sudo systemctl start shadowsocks