#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    build-essential \
    wget

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker and enable on boot
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install yq
YQ_VERSION="v4.35.1"
YQ_BINARY="yq_linux_$(dpkg --print-architecture)"
wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}" -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# Clone lean-quickstart repository
cd /home/ubuntu
git clone https://github.com/blockblaz/lean-quickstart.git
chown -R ubuntu:ubuntu lean-quickstart

# Pull Docker images
docker pull g11tech/zeam:latest
docker pull ghcr.io/reamlabs/ream:latest
docker pull qdrvm/qlean-mini:dd67521

# Set up log directory
mkdir -p /home/ubuntu/logs
chown -R ubuntu:ubuntu /home/ubuntu/logs

# Create systemd service for consensus nodes
cat > /etc/systemd/system/consensus-nodes.service <<'EOF'
[Unit]
Description=Lean Consensus Nodes
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/lean-quickstart
Environment="NETWORK_DIR=local-devnet"
ExecStart=/bin/bash -c 'NETWORK_DIR=local-devnet ./spin-node.sh --node all --generateGenesis --validatorConfig ./local-devnet/genesis/validator-config.yaml'
Restart=on-failure
RestartSec=10s
StandardOutput=append:/home/ubuntu/logs/consensus-nodes.log
StandardError=append:/home/ubuntu/logs/consensus-nodes-error.log

[Install]
WantedBy=multi-user.target
EOF

# Enable service but don't start it yet
systemctl daemon-reload
systemctl enable consensus-nodes.service

# Create helper scripts
cat > /home/ubuntu/start-nodes.sh <<'EOF'
#!/bin/bash
cd /home/ubuntu/lean-quickstart
NETWORK_DIR=local-devnet ./spin-node.sh --node all --generateGenesis --validatorConfig ./local-devnet/genesis/validator-config.yaml
EOF
chmod +x /home/ubuntu/start-nodes.sh
chown ubuntu:ubuntu /home/ubuntu/start-nodes.sh

cat > /home/ubuntu/check-nodes.sh <<'EOF'
#!/bin/bash
echo "=== Docker Containers ==="
docker ps -a

echo -e "\n=== Node Logs (last 20 lines each) ==="
for node in zeam_0 ream_0 qlean_0; do
    echo -e "\n--- $node ---"
    docker logs $node 2>&1 | tail -20
done

echo -e "\n=== Metrics Endpoints ==="
curl -s http://localhost:8080/metrics | grep -E "^(zeam_|# HELP)" | head -5
curl -s http://localhost:8081/metrics | grep -E "^(ream_|# HELP)" | head -5
curl -s http://localhost:8082/metrics | grep -E "^(qlean_|# HELP)" | head -5
EOF
chmod +x /home/ubuntu/check-nodes.sh
chown ubuntu:ubuntu /home/ubuntu/check-nodes.sh

# Create README in home directory
cat > /home/ubuntu/README.md <<'EOF'
# Lean Consensus Node Setup

This EC2 instance is configured to run lean-consensus nodes.

## Quick Start

1. Start all nodes:
   ```bash
   ./start-nodes.sh
   ```

2. Check node status:
   ```bash
   ./check-nodes.sh
   ```

3. View live logs:
   ```bash
   docker logs -f zeam_0
   docker logs -f ream_0
   docker logs -f qlean_0
   ```

## Manual Commands

Run specific nodes:
```bash
cd lean-quickstart
NETWORK_DIR=local-devnet ./spin-node.sh --node zeam_0 --generateGenesis
NETWORK_DIR=local-devnet ./spin-node.sh --node zeam_0,ream_0 --generateGenesis
```

Stop all nodes:
```bash
docker rm -f zeam_0 ream_0 qlean_0
```

## Metrics

- zeam_0: http://localhost:8080/metrics
- ream_0: http://localhost:8081/metrics
- qlean_0: http://localhost:8082/metrics

## Systemd Service

Start service:
```bash
sudo systemctl start consensus-nodes
```

Check status:
```bash
sudo systemctl status consensus-nodes
```

View logs:
```bash
journalctl -u consensus-nodes -f
```
EOF
chown ubuntu:ubuntu /home/ubuntu/README.md

# Signal completion
touch /var/lib/cloud/instance/user-data-complete
