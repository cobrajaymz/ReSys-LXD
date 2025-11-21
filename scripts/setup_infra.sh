#!/bin/bash
set -e

echo "[1/10] Creating project ReSys…"
lxc project create ReSys || true
lxc project switch ReSys

echo "[2/10] Creating networks…"
lxc network create resys_dc_net ipv4.address=10.10.10.1/24 ipv4.nat=true ipv6.address=none
lxc network create resys_app_net ipv4.address=10.10.20.1/24 ipv4.nat=true ipv6.address=none

echo "[3/10] Creating profiles…"

# Datacenter profile
lxc profile create resys_dc_profile || true
cat <<EOF | lxc profile edit resys_dc_profile
config: {}
description: "ReSys Datacenter Profile"
devices:
  eth0:
    name: eth0
    network: resys_dc_net
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: resys_dc_profile
EOF

# App profile
lxc profile create resys_app_profile || true
cat <<EOF | lxc profile edit resys_app_profile
config: {}
description: "ReSys Application Profile"
devices:
  eth0:
    name: eth0
    network: resys_app_net
    type: nic
  root:
    path: /
    pool: default
    type: disk
name: resys_app_profile
EOF

echo "[4/10] Launching containers…"
lxc launch ubuntu:24.04 dc1 -p resys_dc_profile
lxc launch ubuntu:24.04 dc2 -p resys_dc_profile
lxc launch ubuntu:24.04 app1 -p resys_app_profile
lxc launch ubuntu:24.04 app2 -p resys_app_profile

echo "[5/10] Waiting for containers to get IPs…"
sleep 10

echo "[6/10] Creating user + SSH setup in all containers…"
SSH_PUB_KEY=$(cat ~/.ssh/id_rsa.pub)

for c in dc1 dc2 app1 app2; do
    echo "Setting up $c ..."
    lxc exec $c -- bash -c "
        apt update -y &&
        apt install -y openssh-server net-tools &&
        useradd -m admin &&
        mkdir -p /home/admin/.ssh &&
        echo \"$SSH_PUB_KEY\" > /home/admin/.ssh/authorized_keys &&
        chown -R admin:admin /home/admin/.ssh &&
        chmod 600 /home/admin/.ssh/authorized_keys
    "
done

echo "[7/10] Setting hostnames…"
lxc exec dc1 -- hostnamectl set-hostname dc1
lxc exec dc2 -- hostnamectl set-hostname dc2
lxc exec app1 -- hostnamectl set-hostname app1
lxc exec app2 -- hostnamectl set-hostname app2

echo "[8/10] Updating all containers…"
for c in dc1 dc2 app1 app2; do
    lxc exec $c -- apt upgrade -y
done

echo "[9/10] Showing network assignments…"
lxc list

echo "[10/10] ReSys infrastructure deployment complete!"
