#!/usr/bin/env bash
wget https://github.com/shadowsocks/shadowsocks-go/releases/download/1.2.1/shadowsocks-server.tar.gz
tar xvfz shadowsocks-server.tar.gz
rm -rf shadowsocks-server.tar.gz

sudo bash -c 'cat >~/config.json <<EOL
{
    "server":"0.0.0.0",
    "server_port":443,
    "password":"holymoly",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": true
}
EOL'

sudo bash -c 'cat >/lib/systemd/system/ssocks.service <<EOL
[Unit]
Description=ssocks daemon
[Service]
ExecStart=/home/ubuntu/shadowsocks-server -c /home/ubuntu/config.json
Restart=always
User=root
Group=root
[Install]
WantedBy=multi-user.target
EOL'

sudo systemctl daemon-reload
sudo systemctl enable ssocks.service
sudo systemctl start ssocks
