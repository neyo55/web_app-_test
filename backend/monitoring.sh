#!/bin/bash

# monitoring.sh

# Set non-interactive mode to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Log file
LOG_FILE="/var/log/monitoring_setup.log"
exec > >(tee -i $LOG_FILE) 2>&1

echo "Starting monitoring tools installation..."

# Update and install prerequisites
echo "Updating package lists and installing prerequisites..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y wget tar software-properties-common

# Install Prometheus
echo "Installing Prometheus..."
PROMETHEUS_VERSION="2.53.2"
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar -xvzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64 /usr/local/prometheus
rm prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

# Create Prometheus systemd service
echo "Setting up Prometheus systemd service..."
sudo bash -c "cat > /etc/systemd/system/prometheus.service" <<EOL
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=ubuntu
ExecStart=/usr/local/prometheus/prometheus \
  --config.file=/usr/local/prometheus/prometheus.yml \
  --storage.tsdb.path=/usr/local/prometheus/data

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
echo "Prometheus installed and running."

# Install Grafana
echo "Installing Grafana..."
sudo apt-get install -y apt-transport-https
sudo bash -c "echo 'deb https://packages.grafana.com/oss/deb stable main' > /etc/apt/sources.list.d/grafana.list"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y grafana

sudo systemctl enable grafana-server
sudo systemctl start grafana-server
echo "Grafana installed and running."

# Install Node Exporter
echo "Installing Node Exporter..."
NODE_EXPORTER_VERSION="1.8.2"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xvzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

# Create Node Exporter systemd service
echo "Setting up Node Exporter systemd service..."
sudo bash -c "cat > /etc/systemd/system/node_exporter.service" <<EOL
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=ubuntu
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
echo "Node Exporter installed and running."

# Configure Prometheus to scrape metrics
echo "Configuring Prometheus to scrape metrics..."
sudo bash -c "cat > /usr/local/prometheus/prometheus.yml" <<EOL
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['54.217.141.168:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['54.217.141.168:9100']

  - job_name: 'app'
    static_configs:
      - targets: ['54.217.141.168:5000']
EOL

# Restart Prometheus to apply configuration
sudo systemctl restart prometheus
echo "Prometheus configuration updated."

# Output access instructions
echo "Installation complete. Access your monitoring tools:"
echo "- Prometheus: http://54.217.141.168:9090"
echo "- Grafana: http://54.217.141.168:3000 (Default login: admin / admin)"
echo "- Node Exporter metrics: http://54.217.141.168:9100/metrics"

echo "Monitoring tools setup finished successfully."
