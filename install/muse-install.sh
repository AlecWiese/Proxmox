#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y python3
$STD apt-get install -y python3-pip
$STD apt-get install -y git
$STD apt-get install -y ffmpeg
msg_ok "Installed Dependencies"

msg_info "Installing Muse"
$STD git clone https://github.com/Cog-Creators/Red-DiscordBot.git /opt/muse
cd /opt/muse
$STD python3 -m pip install -U pip setuptools wheel
$STD python3 -m pip install -U Red-DiscordBot
msg_ok "Installed Muse"

msg_info "Creating Service User"
$STD useradd -m -s /bin/bash muse
msg_ok "Created Service User"

msg_info "Setting up Muse"
$STD sudo -u muse mkdir /opt/muse/data
$STD sudo -u muse /usr/local/bin/redbot-setup --no-prompt --instance-name "muse" --data-path "/opt/muse/data"
msg_ok "Set up Muse"

msg_info "Creating Service"
service_path="/etc/systemd/system/muse.service"
echo "[Unit]
Description=Muse Discord Bot
After=network.target

[Service]
ExecStart=/usr/local/bin/redbot muse --no-prompt
User=muse
Group=muse
Type=idle
Restart=always
RestartSec=15
RestartPreventExitStatus=0
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target" >$service_path
$STD systemctl enable --now muse.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"