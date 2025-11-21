#!/bin/bash
# Script to set up ReSys multi-tier container infrastructure

set -e
# projects 
lxc project create ReSys 
lxc project switch ReSys
# Networks
echo "Creating LXD networks..."
sudo lxc network create resys_dc_net ipv4.address=10.10.10.1/24 ipv4.nat=true ipv6.address=none || echo "Network already exists"
sudo lxc network create resys_app_net ipv4.address=10.10.20.1/24 ipv4.nat=true ipv6.address=none || echo "Network already exists"

# Profile
echo "Creating LXD profile..."
cat <<EOF | sudo lxc profile edit resys_profile
config:
  limits.cpu: "2"
  limits.memory: 1GB
description: ReSys container profile
devices:
  eth0:
    name: eth0
    network: resys_dc_net
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: resys_profile
EOF

# Containers
echo "Launching containers..."
# Datacenter
sudo lxc launch ubuntu:24.04 resys-dc1 -p resys_profile
sudo lxc launch ubuntu:24.04 resys-dc2 -p resys_profile

# App servers
sudo lxc profile device set resys_profile eth0 network resys_app_net
sudo lxc launch ubuntu:24.04 resys-app1 -p resys_profile
sudo lxc launch ubuntu:24.04 resys-app2 -p resys_profile

echo "Containers launched successfully!"

