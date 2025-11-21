#!/bin/bash
set -e

echo "====== ReSys Test Suite ======"

echo "[1/12] List containers"
lxc list

echo "[2/12] Testing SSH access to all containers..."
for c in dc1 dc2 app1 app2; do
    echo "--- Testing $c ---"
    ssh -o StrictHostKeyChecking=no admin@$(lxc list $c -c4 --format csv | cut -d' ' -f1) "hostname"
done

echo "[3/12] Testing ping DC ↔ DC..."
lxc exec dc1 -- ping -c 2 dc2

echo "[4/12] Testing ping APP ↔ APP..."
lxc exec app1 -- ping -c 2 app2

echo "[5/12] Testing cross-subnet routing (should work only if admin allows)"
lxc exec dc1 -- ping -c 2 app1 || echo "Expected behavior: blocked unless routing rules added."

echo "[6/12] Creating snapshots..."
for c in dc1 dc2 app1 app2; do
    lxc snapshot $c pre_test_snap
done

echo "[7/12] Disk expansion test..."
lxc config device set dc1 root size=5GB

echo "[8/12] Testing container migration to other network..."
lxc network attach resys_app_net dc1 eth1
lxc exec dc1 -- ip a

echo "[9/12] Disk full crisis simulation..."
lxc exec dc1 -- bash -c "fallocate -l 200M /bigfill || true"

echo "[10/12] GRUB recovery simulation (create fake broken boot files)..."
lxc exec dc1 -- mv /boot/grub /boot/grub.broken || true

echo "[11/12] Checking container logs..."
lxc info dc1 --show-log

echo "[12/12] Tests complete!"
