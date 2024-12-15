#!/bin/bash

# alertmanager_setup.sh

# Set non-interactive mode to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Log file setup
LOG_FILE="/var/log/alertmanager_setup.log"
sudo mkdir -p /var/log
sudo touch "$LOG_FILE"
sudo chmod 664 "$LOG_FILE"
exec > >(tee -i "$LOG_FILE") 2>&1

echo "Starting Alertmanager setup..."

# Update and install prerequisites
echo "Updating package lists and installing prerequisites..."
sudo apt-get update -y && sudo apt-get install -y wget curl tar || { echo "Failed to install prerequisites"; exit 1; }

# Install Alertmanager
echo "Installing Alertmanager..."
ALERTMANAGER_VERSION="0.27.0"
wget https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz || { echo "Failed to download Alertmanager"; exit 1; }
tar -xvzf alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
sudo mv alertmanager-${ALERTMANAGER_VERSION}.linux-amd64 /usr/local/alertmanager
rm alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz

# Create Alertmanager configuration
echo "Configuring Alertmanager..."
sudo bash -c "cat > /usr/local/alertmanager/config.yml" <<EOL
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'aesgroupalfa@gmail.com'
  smtp_auth_username: 'aesgroupalfa@gmail.com'
  smtp_auth_password: 'ovfv lxfe xsmo nfbc'
  smtp_require_tls: true

route:
  receiver: 'email-alert'

receivers:
  - name: 'email-alert'
    email_configs:
      - to: 'kbneyo55@gmail.com'
EOL

# Create Alertmanager systemd service
echo "Creating Alertmanager systemd service..."
sudo bash -c "cat > /etc/systemd/system/alertmanager.service" <<EOL
[Unit]
Description=Prometheus Alertmanager
After=network.target

[Service]
User=ubuntu
ExecStart=/usr/local/alertmanager/alertmanager \
  --config.file=/usr/local/alertmanager/config.yml \
  --storage.path=/usr/local/alertmanager/data
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Set permissions and start Alertmanager
sudo mkdir -p /usr/local/alertmanager/data
sudo chown -R ubuntu:ubuntu /usr/local/alertmanager
sudo chmod -R 775 /usr/local/alertmanager
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager
echo "Alertmanager installed and running."

# Integrate Alertmanager with Prometheus
echo "Integrating Alertmanager with Prometheus..."
PROMETHEUS_CONFIG="/usr/local/prometheus/prometheus.yml"
sudo bash -c "cat >> $PROMETHEUS_CONFIG" <<EOL

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - '34.248.180.179:9093'

rule_files:
  - "/usr/local/prometheus/alert_rules.yml"
EOL

# Create alert rules for Prometheus
echo "Creating alert rules..."
sudo bash -c "cat > /usr/local/prometheus/alert_rules.yml" <<EOL
groups:
  - name: example-alerts
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ \$labels.instance }} down"
          description: "{{ \$labels.instance }} of job {{ \$labels.job }} has been down for more than 1 minute."

      - alert: HighCpuUsage
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected on {{ \$labels.instance }}"
          description: "CPU usage above 80% for the past minute on {{ \$labels.instance }}."

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 80
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage detected on {{ \$labels.instance }}"
          description: "Memory usage above 80% for the past minute on {{ \$labels.instance }}."

      - alert: HighDiskUsage
        expr: (node_filesystem_size_bytes{fstype!~"tmpfs|rootfs"} - node_filesystem_avail_bytes{fstype!~"tmpfs|rootfs"}) / node_filesystem_size_bytes{fstype!~"tmpfs|rootfs"} * 100 > 90
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "High disk usage detected on {{ \$labels.instance }}"
          description: "Disk usage above 90% for the past minute on {{ \$labels.instance }}."
EOL

# Set permissions for Prometheus files and restart
sudo chmod -R 775 /usr/local/prometheus
sudo chown -R ubuntu:ubuntu /usr/local/prometheus
sudo systemctl restart prometheus
echo "Prometheus configuration updated to include Alertmanager."

# Output access instructions
echo "Alertmanager setup complete. Access your monitoring tools:"
echo "- Prometheus: http://34.248.180.179:9090"
echo "- Alertmanager: http://34.248.180.179:9093"
echo "Alerts will be sent to: kbneyo55@gmail.com"

echo "Setup finished successfully."






















# #!/bin/bash

# # alertmanager_setup.sh

# # Set non-interactive mode to suppress prompts
# export DEBIAN_FRONTEND=noninteractive

# # Log files and permissions setup
# LOG_FILE="/var/log/alertmanager_setup.log"
# sudo touch "$LOG_FILE"
# sudo chmod 664 "$LOG_FILE"
# exec > >(tee -i "$LOG_FILE") 2>&1

# echo "Starting Alertmanager setup..."

# # Update package lists
# echo "Updating package lists..."
# sudo apt-get update -y && sudo apt-get install -y wget curl tar apt-transport-https || { echo "Error installing dependencies"; exit 1; }

# # Create directories
# echo "Creating necessary directories..."
# sudo mkdir -p /usr/local/alertmanager/data
# sudo mkdir -p /etc/prometheus
# sudo chown -R ubuntu:ubuntu /usr/local/alertmanager /etc/prometheus
# sudo chmod -R 775 /usr/local/alertmanager /etc/prometheus

# # Install Alertmanager
# ALERTMANAGER_VERSION="0.27.0"
# echo "Installing Alertmanager version $ALERTMANAGER_VERSION..."
# wget https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz || { echo "Failed to download Alertmanager"; exit 1; }
# tar -xvzf alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
# sudo mv alertmanager-${ALERTMANAGER_VERSION}.linux-amd64 /usr/local/alertmanager
# sudo ln -s /usr/local/alertmanager/alertmanager /usr/local/bin/alertmanager
# rm alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz

# # Configure Alertmanager
# echo "Configuring Alertmanager..."
# sudo bash -c "cat > /usr/local/alertmanager/config.yml" <<EOL
# global:
#   smtp_smarthost: 'smtp.gmail.com:587'
#   smtp_from: 'aesgroupalfa@gmail.com'
#   smtp_auth_username: 'aesgroupalfa@gmail.com'
#   smtp_auth_password: 'ovfv lxfe xsmo nfbc'
#   smtp_require_tls: true

# route:
#   receiver: 'email-alert'

# receivers:
#   - name: 'email-alert'
#     email_configs:
#       - to: 'kbneyo55@gmail.com'
# EOL

# # Create systemd service for Alertmanager
# echo "Setting up Alertmanager systemd service..."
# sudo bash -c "cat > /etc/systemd/system/alertmanager.service" <<EOL
# [Unit]
# Description=Prometheus Alertmanager
# After=network.target

# [Service]
# User=ubuntu
# ExecStart=/usr/local/bin/alertmanager --config.file=/usr/local/alertmanager/config.yml --storage.path=/usr/local/alertmanager/data
# Restart=always

# [Install]
# WantedBy=multi-user.target
# EOL

# sudo systemctl daemon-reload
# sudo systemctl enable alertmanager
# sudo systemctl start alertmanager || { echo "Failed to start Alertmanager"; exit 1; }

# # Integrate Alertmanager with Prometheus
# PROMETHEUS_CONFIG="/etc/prometheus/prometheus.yml"
# echo "Integrating Alertmanager with Prometheus..."
# if [ ! -f "$PROMETHEUS_CONFIG" ]; then
#     echo "Creating Prometheus configuration file..."
#     sudo bash -c "cat > $PROMETHEUS_CONFIG" <<EOL
# global:
#   scrape_interval: 15s

# alerting:
#   alertmanagers:
#     - static_configs:
#         - targets: ['54.229.161.56:9093']

# rule_files:
#   - "/etc/prometheus/alert_rules.yml"

# scrape_configs:
#   - job_name: 'prometheus'
#     static_configs:
#       - targets: ['localhost:9090']
# EOL
# else
#     sudo sed -i '/alertmanagers:/d' "$PROMETHEUS_CONFIG"
#     sudo bash -c "cat >> $PROMETHEUS_CONFIG" <<EOL

# alerting:
#   alertmanagers:
#     - static_configs:
#         - targets: ['54.229.161.56:9093']
# EOL
# fi

# # Add alert rules for Prometheus
# echo "Adding alert rules..."
# sudo bash -c "cat > /etc/prometheus/alert_rules.yml" <<EOL
# groups:
#   - name: instance-alerts
#     rules:
#       - alert: InstanceDown
#         expr: up == 0
#         for: 1m
#         labels:
#           severity: critical
#         annotations:
#           summary: "Instance {{ \$labels.instance }} is down"
#           description: "The instance {{ \$labels.instance }} has been down for more than 1 minute."

#       - alert: HighCPUUsage
#         expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
#         for: 1m
#         labels:
#           severity: warning
#         annotations:
#           summary: "High CPU usage on {{ \$labels.instance }}"
#           description: "CPU usage has been over 80% for 1 minute."
# EOL

# # Restart Prometheus to apply changes
# sudo systemctl restart prometheus || { echo "Failed to restart Prometheus"; exit 1; }

# # Verify service statuses
# echo "Verifying services..."
# sudo systemctl status alertmanager
# sudo systemctl status prometheus

# # Output success message
# echo "Alertmanager setup complete. Access your tools at:"
# echo "Prometheus: http://54.229.161.56:9090"
# echo "Alertmanager: http://54.229.161.56:9093"
# echo "Alerts will be sent to kbneyo55@gmail.com"