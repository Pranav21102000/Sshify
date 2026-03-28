#!/bin/bash

CONFIG_FILE="config.json"

install_go() {
  echo "[+] Installing Go..."
  rm -rf /usr/local/go
  wget -q https://go.dev/dl/go1.26.1.linux-amd64.tar.gz
  tar -C /usr/local -xzf go1.26.1.linux-amd64.tar.gz
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
  export PATH=$PATH:/usr/local/go/bin
  source ~/.bashrc
  go version
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
  echo "[+] First-time setup"

  read -p "Enter bind address (default 0.0.0.0): " addr
  addr=${addr:-0.0.0.0}

  read -p "Enter port (default 80): " port
  port=${port:-80}

  read -p "Enter username: " user
  read -p "Enter password: " pass

  cat <<EOF > $CONFIG_FILE
{
  "addr": "$addr",
  "port": $port,
  "banner": "Welcome to ssh-ify!\n",
  "users": [
    {
      "user": "$user",
      "pass": "$pass"
    }
  ]
}
EOF

  echo "[+] Config created"
}

change_credentials() {
  echo "[+] Change user/password"

  read -p "New username: " user
  read -p "New password: " pass

  # replace inside JSON
  sed -i "s/\"user\": \".*\"/\"user\": \"$user\"/" $CONFIG_FILE
  sed -i "s/\"pass\": \".*\"/\"pass\": \"$pass\"/" $CONFIG_FILE

  echo "[+] Credentials updated"
}

start_service() {
  echo "[+] Starting ssh-ify..."
  nohup ssh-ify > sshify.log 2>&1 &
  echo "[+] Running in background (log: sshify.log)"
}

menu() {
  echo ""
  echo "1) Install & Setup"
  echo "2) Change user/pass"
  echo "3) Start ssh-ify"
  echo "4) Exit"
  echo ""

  read -p "Choose option: " opt

  case $opt in
    1)
      install_go
      install_sshify
      generate_ssh_key
      create_config
      start_service
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

# Run menu loop
while true; do
  menu
done
