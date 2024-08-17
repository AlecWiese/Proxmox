#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

# Define msg_* functions if they're not available
msg_info() {
  echo -e "\e[1;33m[INFO]\e[0m $1"
}

msg_ok() {
  echo -e "\e[1;32m[OK]\e[0m $1"
}

msg_error() {
  echo -e "\e[1;31m[ERROR]\e[0m $1"
}

# Function to check if a command executed successfully
check_command() {
  if [ $? -ne 0 ]; then
    msg_error "Failed to execute: $1"
    exit 1
  fi
}

header_info() {
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

msg_info "Installing Dependencies"
apt-get update
check_command "apt-get update"
apt-get install -y curl jq ffmpeg python3-pip python3-venv
check_command "apt-get install dependencies"
msg_ok "Installed Dependencies"

msg_info "Installing yt-dlp"
python3 -m venv /opt/yt-dlp-venv
source /opt/yt-dlp-venv/bin/activate
pip install --no-cache-dir yt-dlp
check_command "pip install yt-dlp"
deactivate
ln -s /opt/yt-dlp-venv/bin/yt-dlp /usr/local/bin/yt-dlp
msg_ok "Installed yt-dlp"

msg_info "Installing Go"
GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | tr -d '\n')
if [ -z "$GO_VERSION" ]; then
    msg_error "Failed to get Go version. Please check your internet connection."
    exit 1
fi
msg_info "Downloading Go version: $GO_VERSION"
GO_URL="https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
msg_info "Download URL: $GO_URL"
wget -q "$GO_URL" -O /tmp/go.tar.gz
if [ $? -ne 0 ]; then
    msg_error "Failed to download Go. URL: $GO_URL"
    msg_info "Trying alternative download method..."
    curl -L "$GO_URL" -o /tmp/go.tar.gz
    if [ $? -ne 0 ]; then
        msg_error "Both wget and curl failed to download Go. Please check your internet connection and firewall settings."
        exit 1
    fi
fi
tar -C /usr/local -xzf /tmp/go.tar.gz
if [ $? -ne 0 ]; then
    msg_error "Failed to extract Go archive. Please check if there's enough disk space."
    exit 1
fi
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.bashrc
go version
if [ $? -ne 0 ]; then
    msg_error "Go installation seems to have failed. 'go version' command not found."
    exit 1
fi
msg_ok "Installed Go version: $(go version)"

msg_info "Installing Media Roller"
go install github.com/rroller/media-roller@latest
check_command "go install Media Roller"
mv ~/go/bin/media-roller /usr/local/bin/
check_command "mv Media Roller"
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

systemctl daemon-reload
systemctl enable media-roller.service
systemctl start media-roller.service
check_command "start Media Roller service"
msg_ok "Created Media Roller Service"

msg_info "Cleaning up"
apt-get autoremove -y
apt-get autoclean -y
msg_ok "Cleaned"

msg_ok "Completed Successfully!"
echo -e "\nMedia Roller should now be running as a service."
echo -e "You can check its status with: systemctl status media-roller"
echo -e "Configuration file is located at: /root/.config/media-roller/config.yaml"
echo -e "Remember to configure your media directories and other settings in the config file."
echo -e "Media Roller should be reachable by going to the following URL."
echo -e "http://$(hostname -I | awk '{print $1}'):8080\n"