#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____  ____  _   _______    __  ______  ____  ___  __________  __________ 
   / __ \/ __ \/ | / / ___/   / / / / __ \/ __ \/   |/_  __/ __ \/ ____/ __ \
  / / / / / / /  |/ /\__ \   / / / / /_/ / / / / /| | / / / / / / __/ / /_/ /
 / /_/ / /_/ / /|  /___/ /  / /_/ / ____/ /_/ / ___ |/ / / /_/ / /___/ _, _/ 
/_____/_____/_/ |_//____/   \____/_/   /_____/_/  |_/_/ /_____/_____/_/ |_|  
                                                                                                                                          
EOF
}
header_info
echo -e "Loading..."
APP="DDNS-Updater"
var_disk="2"
var_cpu="1"
var_ram="512"
var_os="debian"
var_version="11"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
  if [[ ! -f /usr/local/bin/ddns-updater ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 10 58 1 \
    "1" "Update DDNS-Updater" ON \
    3>&1 1>&2 2>&3)

  header_info
  if [ "$UPD" == "1" ]; then
    msg_info "Updating ${APP}"
    ARCH=$(dpkg --print-architecture)
    LATEST_VERSION=$(curl -s https://api.github.com/repos/qdm12/ddns-updater/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    wget -q "https://github.com/qdm12/ddns-updater/releases/download/${LATEST_VERSION}/ddns-updater_${LATEST_VERSION#v}_linux_${ARCH}" -O /usr/local/bin/ddns-updater
    chmod +x /usr/local/bin/ddns-updater
    systemctl restart ddns-updater
    msg_ok "Updated ${APP}"
    exit
  fi
}

start
build_container
description

msg_info "Installing ${APP}"
ARCH=$(dpkg --print-architecture)
LATEST_VERSION=$(curl -s https://api.github.com/repos/qdm12/ddns-updater/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
wget -q "https://github.com/qdm12/ddns-updater/releases/download/${LATEST_VERSION}/ddns-updater_${LATEST_VERSION#v}_linux_${ARCH}" -O /usr/local/bin/ddns-updater
chmod +x /usr/local/bin/ddns-updater

cat <<EOF > /etc/systemd/system/ddns-updater.service
[Unit]
Description=DDNS Updater
After=network.target

[Service]
ExecStart=/usr/local/bin/ddns-updater
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ddns-updater
systemctl start ddns-updater

msg_ok "Installed ${APP}"

msg_ok "Completed Successfully!\n"
echo -e "${APP} has been installed and is running as a system service.\n"
echo -e "You may need to configure it by editing the config file at /etc/ddns-updater.json\n"
echo -e "For more information, please visit: ${BL}https://github.com/qdm12/ddns-updater${CL}\n"