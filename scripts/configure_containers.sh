#!/bin/bash
# Script to configure containers: static IP, SSH keys, /etc/hosts

set -e

# Define IPs
declare -A ips=(
  [resys-dc1]="10.10.10.11"
  [resys-dc2]="10.10.10.12"
  [resys-app1]="10.10.20.11"
  [resys-app2]="10.10.20.12"
)

# Configure Netplan
echo "Configuring static IPs..."
for c in "${!ips[@]}"; do
  sudo lxc exec $c -- bash -c "mkdir -p /etc/netplan"
  sudo lxc exec $c -- bash -c "cat > /etc/netplan/50-static.yaml <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses: [${ips[$c]}/24]
      routes:
        - to: default
          via: ${ips[$c]%.*}.1
      nameservers:
        addresses: [8.8.8.8,1.1.1.1]
EOF"
  sudo lxc exec $c -- chmod 600 /etc/netplan/50-static.yaml
  sudo lxc exec $c -- netplan apply
done

# Set /etc/hosts for hostname resolution
echo "Setting /etc/hosts..."
for c in "${!ips[@]}"; do
  for h in "${!ips[@]}"; do
    sudo lxc exec $c -- bash -c "echo '${ips[$h]} $h' >> /etc/hosts"
  done
done

# Generate SSH keys and distribute
echo "Generating SSH keys..."
for c in "${!ips[@]}"; do
  sudo lxc exec $c -- ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N "" || true
done

echo "Distributing SSH keys..."
for c in "${!ips[@]}"; do
  for h in "${!ips[@]}"; do
    key=$(sudo lxc exec $c -- cat /root/.ssh/id_ed25519.pub)
    sudo lxc exec $h -- bash -c "mkdir -p ~/.ssh && echo '$key' >> ~/.ssh/authorized_keys"
  done
done

echo "Container configuration completed!"

#!/bin/bash

# List of all containers
CONTAINERS=(resys-dc1 resys-dc2 resys-app1 resys-app2)

for c in "${CONTAINERS[@]}"; do
    echo "Setting up resource monitoring on $c..."

    # Update and install monitoring packages
    sudo lxc exec $c -- apt update
    sudo lxc exec $c -- apt install -y htop sysstat net-tools

    # Enable sysstat data collection
    sudo lxc exec $c -- sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
    sudo lxc exec $c -- systemctl restart sysstat

    # Create a simple monitoring script inside the container
    sudo lxc exec $c -- bash -c 'cat > ~/monitor.sh <<EOF
#!/bin/bash
# Simple resource monitor script
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
mkdir -p ~/monitor_logs
echo "CPU and Memory usage at \$DATE" >> ~/monitor_logs/monitor.log
top -b -n1 | head -n 20 >> ~/monitor_logs/monitor.log
echo "Disk usage:" >> ~/monitor_logs/monitor.log
df -h >> ~/monitor_logs/monitor.log
echo "Network stats:" >> ~/monitor_logs/monitor.log
ifconfig >> ~/monitor_logs/monitor.log
echo "-----------------------------" >> ~/monitor_logs/monitor.log
EOF'

    # Make it executable
    sudo lxc exec $c -- chmod +x ~/monitor.sh

    echo "Resource monitoring setup complete for $c"
done

echo "All containers now have basic resource monitoring scripts!"
