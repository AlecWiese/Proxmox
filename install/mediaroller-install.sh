#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    __  ___          ___       ____        ____
   /  |/  /__  ___  / (_)___ _/ __ \____  / / /__  _____
  / /|_/ / _ \/ _ \/ / / __ `/ /_/ / __ \/ / / _ \/ ___/
 / /  / /  __/ // / / / /_/ / _, _/ /_/ / / /  __/ /
/_/  /_/\___/\___/_/_/\__,_/_/ |_|\____/_/_/\___/_/

EOF
}

header_info
echo -e "Loading..."
APP="Media Roller"
WAIT=0

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get install -y curl jq ffmpeg python3-pip
$STD pip3 install --upgrade yt-dlp
msg_ok "Installed Dependencies"

msg_info "Installing Go"
GO_VERSION=$(curl -s https://go.dev/VERSION?m=text)
wget -q https://golang.org/dl/${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz
tar -C /usr/local -xzf /tmp/go.tar.gz
export PATH=$PATH:/usr/local/go/bin
msg_ok "Installed Go"

msg_info "Installing Media Roller"
$STD go install github.com/rroller/media-roller@latest
mv ~/go/bin/media-roller /usr/local/bin/
msg_ok "Installed Media Roller"

msg_info "Creating Media Roller Service"
cat <<EOF > /etc/systemd/system/media-roller.service
[Unit]
Description=Media Roller
After=network.target

[Service]
ExecStart=/usr/local/bin/media-roller
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

$STD systemctl daemon-reload
$STD systemctl enable media-roller.service
$STD systemctl start media-roller.service
msg_ok "Created Media Roller Service"

msg_info "Cleaning up"
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"

msg_ok "Completed Successfully!\n"
echo -e "Media Roller should now be running as a service."
echo -e "You can check its status with: ${BL}systemctl status media-roller${CL}"
echo -e "Configuration file is located at: ${BL}/root/.config/media-roller/config.yaml${CL}"
echo -e "Remember to configure your media directories and other settings in the config file."
echo -e "Media Roller should be reachable by going to the following URL."
echo -e "${BL}http://${IP}:8080${CL}\n"