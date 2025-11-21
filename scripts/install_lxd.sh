#!/bin/bash
set -e

echo "[1/3] Updating system..."
sudo apt update -y
sudo apt upgrade -y

echo "[2/3] Installing LXD..."
sudo apt install -y lxd lxd-client

echo "[3/3] Initializing LXD..."
cat <<EOF | sudo lxd init --preseed
config: {}
networks:
- name: lxdbr0
  type: bridge
  config:
    ipv4.address: auto
    ipv4.nat: "true"
    ipv6.address: none
storage_pools:
- name: default
  driver: dir
profiles:
- name: default
  config: {}
  devices:
    root:
      path: /
      pool: default
      type: disk
cluster: null
EOF

echo "LXD installation complete!"
lxc version
