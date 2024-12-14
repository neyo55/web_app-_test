#!/bin/bash

# master.sh

# Set non-interactive mode to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Set variables
# PROJECT_DIR=$(dirname "$(realpath "$0")")
MYSQL_CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"

# Update Ubuntu and install prerequisites
echo "Updating the package list and installing prerequisites..."
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Install unattended-upgrades to handle future updates automatically
sudo apt install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades

# Notify if a reboot is required without performing it
if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required to apply kernel updates. Please reboot the system at your convenience."
fi

# Log files and permissions setup
echo "Setting up log files..."
for log_file in /var/log/web_data.log /var/log/web_setup.log /var/log/app_data.log /var/log/app_setup.log /var/log/db_data.log /var/log/db_setup.log; do
    sudo touch "$log_file"
    sudo chown ubuntu:ubuntu "$log_file"
    sudo chmod 664 "$log_file"
done

# Grant permissions for gunicorn logs
sudo mkdir -p /var/log/gunicorn
sudo chown -R ubuntu:www-data /var/log/gunicorn
sudo chmod -R 775 /var/log/gunicorn

# Redirect all output for this script
exec > /var/log/web_data.log 2>&1

# Create directories under 'ubuntu' user
for dir in /home/ubuntu/frontend /home/ubuntu/backend /home/ubuntu/database; do
    echo "Creating $dir directory..."
    sudo -u ubuntu mkdir -p "$dir"
done

sudo chown -R ubuntu:www-data /home/ubuntu/backend
sudo chmod -R 755 /home/ubuntu/backend

###### web installations #######
echo "Starting web installations..."

# Install Nginx, PHP, and MySQL extensions
echo "Installing Nginx, PHP, and related dependencies..."
sudo apt install -y nginx php8.1 php8.1-fpm php8.1-mysql

# Install Adminer
echo "Installing Adminer..."
sudo wget -q https://www.adminer.org/latest.php -O /var/www/html/adminer.php || exit_script
sudo chown www-data:www-data /var/www/html/adminer.php || exit_script
sudo chmod 755 /var/www/html/adminer.php || exit_script
echo "Adminer installed successfully."

###### app installations #######
echo "Starting app installations..."

# Install Python and pip3 if not already installed
echo "Checking for Python3 and pip3 installations..."
if ! command -v python3 &> /dev/null; then
    echo "Installing Python3..."
    sudo apt install -y python3
fi
if ! command -v pip3 &> /dev/null; then
    echo "Installing pip3..."
    sudo apt install -y python3-pip
fi

# Install Gunicorn globally if not already installed
echo "Checking for Gunicorn installation..."
if ! pip3 show gunicorn &> /dev/null; then
    echo "Installing Gunicorn..."
    sudo pip3 install gunicorn
fi

# Install Python packages from requirements.txt in the backend directory
REQUIREMENTS_FILE="/home/ubuntu/backend/requirements.txt"
if [[ -f "$REQUIREMENTS_FILE" ]]; then
    echo "Installing Python packages from requirements.txt..."
    sudo pip3 install -r "$REQUIREMENTS_FILE"
else
    echo "requirements.txt file not found in /home/ubuntu/backend."
fi

# Install additional Python packages not in requirements.txt
echo "Installing additional Python packages..."
sudo pip3 install Flask-WTF email-validator prometheus_client

# Verify Python packages
echo "Verifying installed Python packages..."
python3 -c "import flask; import mysql.connector; import dotenv; import gunicorn; import flask_wtf; import email_validator; import prometheus_client" || { echo "Error: Missing required Python packages"; exit 1; }

###### db installations #######
echo "Starting database installations..."

# Install MySQL server
if ! command -v mysql &> /dev/null; then
    echo "Installing MySQL Server..."
    sudo apt install -y mysql-server
fi

# Configure MySQL for remote connections
echo "Configuring MySQL for remote connections..."
MYSQL_CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
if sudo grep -q "^bind-address" "$MYSQL_CONF_FILE"; then
    sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" "$MYSQL_CONF_FILE"
else
    echo "bind-address = 0.0.0.0" | sudo tee -a "$MYSQL_CONF_FILE"
fi
sudo systemctl restart mysql

# Enable and start MySQL service
echo "Enabling and starting MySQL service..."
sudo systemctl enable mysql
sudo systemctl start mysql

# Install Redis server and enable it
echo "Installing Redis server..."
if ! command -v redis-server &> /dev/null; then
    sudo apt install -y redis-server || { echo "Failed to install Redis server"; exit 1; }
    sudo systemctl enable redis-server || { echo "Failed to enable Redis server"; exit 1; }
    sudo systemctl start redis-server || { echo "Failed to start Redis server"; exit 1; }
else
    echo "Redis server is already installed."
fi

# Install Python Redis package with sudo
echo "Installing Python Redis package..."
sudo pip3 install redis || { echo "Failed to install Python Redis package"; exit 1; }