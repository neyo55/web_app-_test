#!/bin/bash

# master.sh

# Set non-interactive mode to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Variables
MYSQL_CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
LOG_FILE="/var/log/master_setup.log"

# Redirect all output to log file
exec > >(tee -a "$LOG_FILE") 2>&1

# Update Ubuntu and install prerequisites
echo "Updating the package list and installing prerequisites..."
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y || { echo "Error: Failed to update and upgrade packages."; exit 1; }

# Install unattended-upgrades to handle future updates automatically
sudo apt install -y unattended-upgrades || { echo "Error: Failed to install unattended-upgrades."; exit 1; }
echo 'Unattended-Upgrade::Automatic-Reboot "false";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades

# Notify if a reboot is required without performing it
if [ -f /var/run/reboot-required ]; then
    echo "====================================================================="
    echo "A reboot is required to apply kernel updates."
    echo "Please reboot the system at your convenience to ensure full functionality."
    echo "====================================================================="
fi

# Log files and permissions setup
echo "Setting up log files..."
for log_file in /var/log/web_data.log /var/log/web_setup.log /var/log/app_data.log /var/log/app_setup.log /var/log/db_data.log /var/log/db_setup.log; do
    sudo touch "$log_file" || { echo "Error: Failed to create $log_file"; exit 1; }
    sudo chown ubuntu:ubuntu "$log_file" || { echo "Error: Failed to set ownership of $log_file"; exit 1; }
    sudo chmod 664 "$log_file" || { echo "Error: Failed to set permissions on $log_file"; exit 1; }
done

# Grant permissions for Gunicorn logs
echo "Setting up Gunicorn logs..."
sudo mkdir -p /var/log/gunicorn || { echo "Error: Failed to create /var/log/gunicorn directory."; exit 1; }
sudo chown -R ubuntu:www-data /var/log/gunicorn || { echo "Error: Failed to set ownership for /var/log/gunicorn."; exit 1; }
sudo chmod -R 775 /var/log/gunicorn || { echo "Error: Failed to set permissions for /var/log/gunicorn."; exit 1; }

# Create directories under 'ubuntu' user
echo "Creating project directories..."
for dir in /home/ubuntu/frontend /home/ubuntu/backend /home/ubuntu/database; do
    sudo -u ubuntu mkdir -p "$dir" || { echo "Error: Failed to create directory $dir."; exit 1; }
done

sudo chown -R ubuntu:www-data /home/ubuntu || { echo "Error: Failed to set ownership for /home/ubuntu."; exit 1; }
sudo chmod -R 755 /home/ubuntu || { echo "Error: Failed to set permissions for /home/ubuntu."; exit 1; }

###### Web Installations ######
echo "Starting web installations..."

# Certbot Installation with Error Checks
log "Checking if Certbot is already installed..."
if command_exists certbot; then
    log "Certbot is already installed. Skipping installation."
else
    log "Installing Certbot and Certbot Nginx plugin..."
    sudo apt install -y certbot python3-certbot-nginx || { log "Error: Failed to install Certbot."; exit 1; }
    log "Certbot installation completed successfully."
fi

# Install Nginx, PHP, and MySQL extensions
echo "Installing Nginx, PHP, and related dependencies..."
sudo apt install -y nginx php8.1 php8.1-fpm php8.1-mysql || { echo "Error: Failed to install Nginx, PHP, or MySQL extensions."; exit 1; }

# Install Adminer
echo "Installing Adminer..."
sudo wget -q https://www.adminer.org/latest.php -O /var/www/html/adminer.php || { echo "Error: Failed to download Adminer."; exit 1; }
sudo chown www-data:www-data /var/www/html/adminer.php || { echo "Error: Failed to set ownership for Adminer."; exit 1; }
sudo chmod 755 /var/www/html/adminer.php || { echo "Error: Failed to set permissions for Adminer."; exit 1; }
echo "Adminer installed successfully."

###### App Installations ######
echo "Starting app installations..."

# Install Python and pip3 if not already installed
echo "Checking for Python3 and pip3 installations..."
if ! command -v python3 &> /dev/null; then
    echo "Installing Python3..."
    sudo apt install -y python3 || { echo "Error: Failed to install Python3."; exit 1; }
fi
if ! command -v pip3 &> /dev/null; then
    echo "Installing pip3..."
    sudo apt install -y python3-pip || { echo "Error: Failed to install pip3."; exit 1; }
fi

# Install Gunicorn globally if not already installed
echo "Checking for Gunicorn installation..."
if ! pip3 show gunicorn &> /dev/null; then
    echo "Installing Gunicorn..."
    sudo pip3 install gunicorn || { echo "Error: Failed to install Gunicorn."; exit 1; }
fi

# Install Python packages from requirements.txt
REQUIREMENTS_FILE="/home/ubuntu/backend/requirements.txt"
if [[ -f "$REQUIREMENTS_FILE" ]]; then
    echo "Installing Python packages from requirements.txt..."
    sudo pip3 install -r "$REQUIREMENTS_FILE" || { echo "Error: Failed to install Python packages from requirements.txt."; exit 1; }
else
    echo "requirements.txt file not found in /home/ubuntu/backend."
fi

# Install additional Python packages
echo "Installing additional Python packages..."
sudo pip3 install gunicorn Flask-WTF email-validator prometheus_client redis || { echo "Error: Failed to install additional Python packages."; exit 1; }

###### Database Installations ######
echo "Starting database installations..."

# Install MySQL server
if ! command -v mysql &> /dev/null; then
    echo "Installing MySQL Server..."
    sudo apt install -y mysql-server || { echo "Error: Failed to install MySQL server."; exit 1; }
fi

# Configure MySQL for remote connections
echo "Configuring MySQL for remote connections..."
if sudo grep -q "^bind-address" "$MYSQL_CONF_FILE"; then
    sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" "$MYSQL_CONF_FILE" || { echo "Error: Failed to update MySQL bind-address."; exit 1; }
else
    echo "bind-address = 0.0.0.0" | sudo tee -a "$MYSQL_CONF_FILE" || { echo "Error: Failed to add MySQL bind-address."; exit 1; }
fi
sudo systemctl restart mysql || { echo "Error: Failed to restart MySQL."; exit 1; }

# Enable and start MySQL service
echo "Enabling and starting MySQL service..."
sudo systemctl enable mysql || { echo "Error: Failed to enable MySQL."; exit 1; }
sudo systemctl start mysql || { echo "Error: Failed to start MySQL."; exit 1; }

# Install Redis server and enable it
echo "Installing Redis server..."
if ! command -v redis-server &> /dev/null; then
    sudo apt install -y redis-server || { echo "Error: Failed to install Redis server."; exit 1; }
    sudo systemctl enable redis-server || { echo "Error: Failed to enable Redis server."; exit 1; }
    sudo systemctl start redis-server || { echo "Error: Failed to start Redis server."; exit 1; }
else
    echo "Redis server is already installed."
fi

# Install Python Redis package
echo "Installing Python Redis package..."
sudo pip3 install redis || { echo "Error: Failed to install Python Redis package."; exit 1; }

echo "Master script completed successfully."










# #!/bin/bash

# # master.sh

# # Set non-interactive mode to suppress prompts
# export DEBIAN_FRONTEND=noninteractive

# # Variables
# MYSQL_CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
# LOG_FILE="/var/log/master_setup.log"

# # Redirect all output to log file
# exec > >(tee -a "$LOG_FILE") 2>&1

# # Function to log messages
# log() {
#     echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
# }

# # Function to check if a command exists
# command_exists() {
#     command -v "$1" &> /dev/null
# }

# # Update Ubuntu and install prerequisites
# log "Updating the package list and installing prerequisites..."
# sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y || { log "Error: Failed to update and upgrade packages."; exit 1; }

# # Install unattended-upgrades to handle future updates automatically
# sudo apt install -y unattended-upgrades || { log "Error: Failed to install unattended-upgrades."; exit 1; }
# echo 'Unattended-Upgrade::Automatic-Reboot "false";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades

# # Notify if a reboot is required without performing it
# if [ -f /var/run/reboot-required ]; then
#     log "====================================================================="
#     log "A reboot is required to apply kernel updates."
#     log "Please reboot the system at your convenience to ensure full functionality."
#     log "====================================================================="
# fi

# # Certbot Installation with Error Checks
# log "Checking if Certbot is already installed..."
# if command_exists certbot; then
#     log "Certbot is already installed. Skipping installation."
# else
#     log "Installing Certbot and Certbot Nginx plugin..."
#     sudo apt install -y certbot python3-certbot-nginx || { log "Error: Failed to install Certbot."; exit 1; }
#     log "Certbot installation completed successfully."
# fi

# # Log files and permissions setup
# log "Setting up log files..."
# for log_file in /var/log/web_data.log /var/log/web_setup.log /var/log/app_data.log /var/log/app_setup.log /var/log/db_data.log /var/log/db_setup.log; do
#     sudo touch "$log_file" || { log "Error: Failed to create $log_file"; exit 1; }
#     sudo chown ubuntu:ubuntu "$log_file" || { log "Error: Failed to set ownership of $log_file"; exit 1; }
#     sudo chmod 664 "$log_file" || { log "Error: Failed to set permissions on $log_file"; exit 1; }
# done

# # Gunicorn log setup
# log "Setting up Gunicorn logs..."
# sudo mkdir -p /var/log/gunicorn || { log "Error: Failed to create /var/log/gunicorn directory."; exit 1; }
# sudo chown -R ubuntu:www-data /var/log/gunicorn || { log "Error: Failed to set ownership for /var/log/gunicorn."; exit 1; }
# sudo chmod -R 775 /var/log/gunicorn || { log "Error: Failed to set permissions for /var/log/gunicorn."; exit 1; }

# # Create directories under 'ubuntu' user
# log "Creating project directories..."
# for dir in /home/ubuntu/frontend /home/ubuntu/backend /home/ubuntu/database; do
#     sudo -u ubuntu mkdir -p "$dir" || { log "Error: Failed to create directory $dir."; exit 1; }
# done

# sudo chown -R ubuntu:www-data /home/ubuntu || { log "Error: Failed to set ownership for /home/ubuntu."; exit 1; }
# sudo chmod -R 755 /home/ubuntu || { log "Error: Failed to set permissions for /home/ubuntu."; exit 1; }

# log "Master script completed successfully."
