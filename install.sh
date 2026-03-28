#!/bin/bash

CONFIG_FILE="config.json"
MENU_CMD="/usr/local/bin/menu"

get_ip() {
  curl -s ipinfo.io/ip
}

install_go() {
  echo "[+] Installing Go..."
  rm -rf /usr/local/go
  wget -q https://go.dev/dl/go1.26.1.linux-amd64.tar.gz
  tar -C /usr/local -xzf go1.26.1.linux-amd64.tar.gz
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
  export PATH=$PATH:/usr/local/go/bin
}

install_sshify() {
  echo "[+] Installing ssh-ify..."
  export PATH=$PATH:$HOME/go/bin
  go install github.com/FreeNetLabs/ssh-ify@latest
}

generate_ssh_key() {
  echo "[+] Generating SSH key..."
  mkdir -p /root/.ssh
  ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -N "" -q
}

create_config() {
  echo "[+] Creating config..."

  IP=$(get_ip)

  read -p "Enter port (default 80): " port
  port=${port:-80}

  read -p "Enter server message: " banner

  read -p "Enter username: " user
  read -p "Enter password: " pass

  cat <<EOF > $CONFIG_FILE
{
  "addr": "$IP",
  "port": $port,
  "banner": "$banner\n",
  "users": [
    {
      "user": "$user",
      "pass": "$pass"
    }
  ]
}
EOF

  echo "[+] Config created with IP: $IP"
}

change_credentials() {
  read -p "New username: " user
  read -p "New password: " pass

  sed -i "s/\"user\": \".*\"/\"user\": \"$user\"/" $CONFIG_FILE
  sed -i "s/\"pass\": \".*\"/\"pass\": \"$pass\"/" $CONFIG_FILE

  echo "[+] Updated successfully"
}

start_service() {
  echo "[+] Starting ssh-ify..."
  pkill ssh-ify 2>/dev/null
  nohup ssh-ify > sshify.log 2>&1 &
  echo "[+] Running (log: sshify.log)"
}

install_menu() {
  echo "[+] Creating menu command..."
  cp "$0" $MENU_CMD
  chmod +x $MENU_CMD
  echo "[+] Type 'menu' to open panel"
}

menu() {
  clear
  echo "====== SSH-IFY MENU ======"
  echo "1) Install & Setup"
  echo "2) Change User/Pass"
  echo "3) Start Service"
  echo "4) Exit"
  echo "=========================="

  read -p "Choose: " opt

  case $opt in
    1)
      install_go
      install_sshify
      generate_ssh_key
      create_config
      start_service
      install_menu
      ;;
    2)
      change_credentials
      ;;
    3)
      start_service
      ;;
    4)
      exit
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
}

while true; do
  menu
done
