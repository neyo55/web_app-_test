#!/bin/bash

# mysql_setup.sh

# Set variables
PROJECT_DIR=$(dirname "$(realpath "$0")")
LOG_FILE="/var/log/db_setup.log"
ENV_FILE="$PROJECT_DIR/.env"  # Updated to use .env in the same directory
MYSQL_CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to log messages
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Ensure the log file exists and truncate it for a new run
echo "Starting new MySQL setup log..." > "$LOG_FILE"

# Load environment variables
ENV_FILE="/home/ubuntu/database/.env"
if [[ -f "$ENV_FILE" ]]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found in $ENV_FILE"
    exit 1
fi

# Check if MySQL is installed
if command_exists mysql; then
    log "MySQL is already installed."
else
    log "MySQL is not installed. Installing MySQL..."
    
    # Preconfigure MySQL installation prompts
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"

    # Update package index
    sudo apt update | tee -a "$LOG_FILE"

    # Install MySQL server
    sudo apt install -y mysql-server | tee -a "$LOG_FILE"
    if [[ $? -ne 0 ]]; then
        log "Failed to install MySQL server."
        exit 1
    fi

    # Secure MySQL installation
    log "Securing MySQL installation..."
    sudo mysql -u root -p"$DB_ROOT_PASS" <<-EOF
        DELETE FROM mysql.user WHERE User='';
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
        FLUSH PRIVILEGES;
EOF
    if [[ $? -ne 0 ]]; then
        log "Failed to secure MySQL installation."
        exit 1
    fi
fi

# Modify MySQL configuration to allow remote connections
log "Configuring MySQL to allow remote connections..."
if sudo grep -q "^bind-address" "$MYSQL_CONF_FILE"; then
    sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" "$MYSQL_CONF_FILE"
else
    echo "bind-address = 0.0.0.0" | sudo tee -a "$MYSQL_CONF_FILE"
fi

# Restart MySQL to apply the new configuration
log "Restarting MySQL service..."
sudo systemctl restart mysql | tee -a "$LOG_FILE"
if [[ $? -ne 0 ]]; then
    log "Failed to restart MySQL service."
    exit 1
fi

# Check if MySQL service is running
sudo systemctl status mysql | grep "active (running)" &> /dev/null
if [[ $? -ne 0 ]]; then
    log "MySQL service is not running. Starting MySQL..."
    sudo systemctl start mysql | tee -a "$LOG_FILE"
    if [[ $? -ne 0 ]]; then
        log "Failed to start MySQL service."
        exit 1
    fi
else
    log "MySQL service is already running."
fi

# Enable MySQL to start on boot
sudo systemctl enable mysql | tee -a "$LOG_FILE"
if [[ $? -ne 0 ]]; then
    log "Failed to enable MySQL service to start on boot."
    exit 1
fi

# Create or update the database user with remote access
log "Creating or updating MySQL user '$DB_USER'..."
sudo mysql -u root -p"$DB_ROOT_PASS" <<-EOF
    CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
    GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
    FLUSH PRIVILEGES;
EOF
if [[ $? -ne 0 ]]; then
    log "Failed to create or update MySQL user '$DB_USER'."
    exit 1
fi

# Check if the database exists
DB_EXISTS=$(mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -e "SHOW DATABASES LIKE '$DB_NAME';" | grep "$DB_NAME" > /dev/null; echo "$?")
if [[ $DB_EXISTS -eq 0 ]]; then
    log "Database $DB_NAME already exists."
else
    log "Creating database $DB_NAME..."
    
    # Create the database
    mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -e "CREATE DATABASE $DB_NAME;" | tee -a "$LOG_FILE"
    if [[ $? -ne 0 ]]; then
        log "Failed to create database $DB_NAME."
        exit 1
    fi
fi

# Check if the table exists
TABLE_EXISTS=$(mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -D"$DB_NAME" -e "SHOW TABLES LIKE 'users';" | grep "users" > /dev/null; echo "$?")
if [[ $TABLE_EXISTS -eq 0 ]]; then
    log "Table 'users' already exists in database $DB_NAME."
else
    log "Creating table 'users' in database $DB_NAME..."

    # Create the table
    mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -D"$DB_NAME" -e "
    CREATE TABLE users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100),
        email VARCHAR(100),
        phone VARCHAR(20),
        dob DATE,
        gender VARCHAR(10),
        address TEXT
    );" | tee -a "$LOG_FILE"
    if [[ $? -ne 0 ]]; then
        log "Failed to create table 'users' in database $DB_NAME."
        exit 1
    fi

    log "Table 'users' created successfully in database $DB_NAME."
fi

log "MySQL setup completed successfully."























# #!/bin/bash

# # mysql_setup.sh

# # Set variables
# PROJECT_DIR=$(dirname "$(realpath "$0")")
# LOG_FILE="/var/log/db_setup.log"
# ENV_FILE="$PROJECT_DIR/.env"  # Updated to use .env in the same directory
# MYSQL_CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"

# # Function to check if a command exists
# command_exists() {
#     command -v "$1" &> /dev/null
# }

# # Function to log messages
# log() {
#     echo "$1" | tee -a "$LOG_FILE"
# }

# # Ensure the log file exists and truncate it for a new run
# echo "Starting new MySQL setup log..." > "$LOG_FILE"

# # Load environment variables from .env file
# if [ -f "$PROJECT_DIR/.env" ]; then
#     ENV_FILE="$PROJECT_DIR/.env"
# elif [ -f "/home/ubuntu/project-directory/database/.env" ]; then
#     ENV_FILE="/home/ubuntu/project-directory/database/.env"
#     log "Using .env file from $ENV_FILE"
# else
#     log ".env file not found in expected locations."
#     exit 1
# fi

# while IFS= read -r line || [ -n "$line" ]; do
#     if [[ ! $line =~ ^# && $line == *=* ]]; then
#         export "$line"
#     fi
# done < "$ENV_FILE"

# # Check if MySQL is installed
# if command_exists mysql; then
#     log "MySQL is already installed."
# else
#     log "MySQL is not installed. Installing MySQL..."
    
#     # Preconfigure MySQL installation prompts
#     sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
#     sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"

#     # Update package index
#     sudo apt update | tee -a "$LOG_FILE"

#     # Install MySQL server
#     sudo apt install -y mysql-server | tee -a "$LOG_FILE"
#     if [[ $? -ne 0 ]]; then
#         log "Failed to install MySQL server."
#         exit 1
#     fi

#     # Secure MySQL installation
#     log "Securing MySQL installation..."
#     sudo mysql -u root -p"$DB_ROOT_PASS" <<-EOF
#         DELETE FROM mysql.user WHERE User='';
#         DROP DATABASE IF EXISTS test;
#         DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
#         FLUSH PRIVILEGES;
# EOF
#     if [[ $? -ne 0 ]]; then
#         log "Failed to secure MySQL installation."
#         exit 1
#     fi
# fi

# # Modify MySQL configuration to allow remote connections
# log "Configuring MySQL to allow remote connections..."
# if sudo grep -q "^bind-address" "$MYSQL_CONF_FILE"; then
#     sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" "$MYSQL_CONF_FILE"
# else
#     echo "bind-address = 0.0.0.0" | sudo tee -a "$MYSQL_CONF_FILE"
# fi

# # Restart MySQL to apply the new configuration
# log "Restarting MySQL service..."
# sudo systemctl restart mysql | tee -a "$LOG_FILE"
# if [[ $? -ne 0 ]]; then
#     log "Failed to restart MySQL service."
#     exit 1
# fi

# # Check if MySQL service is running
# sudo systemctl status mysql | grep "active (running)" &> /dev/null
# if [[ $? -ne 0 ]]; then
#     log "MySQL service is not running. Starting MySQL..."
#     sudo systemctl start mysql | tee -a "$LOG_FILE"
#     if [[ $? -ne 0 ]]; then
#         log "Failed to start MySQL service."
#         exit 1
#     fi
# else
#     log "MySQL service is already running."
# fi

# # Enable MySQL to start on boot
# sudo systemctl enable mysql | tee -a "$LOG_FILE"
# if [[ $? -ne 0 ]]; then
#     log "Failed to enable MySQL service to start on boot."
#     exit 1
# fi

# # Create or update the database user with remote access
# log "Creating or updating MySQL user '$DB_USER'..."
# sudo mysql -u root -p"$DB_ROOT_PASS" <<-EOF
#     CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
#     GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
#     FLUSH PRIVILEGES;
# EOF
# if [[ $? -ne 0 ]]; then
#     log "Failed to create or update MySQL user '$DB_USER'."
#     exit 1
# fi

# # Check if the database exists
# DB_EXISTS=$(mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -e "SHOW DATABASES LIKE '$DB_NAME';" | grep "$DB_NAME" > /dev/null; echo "$?")
# if [[ $DB_EXISTS -eq 0 ]]; then
#     log "Database $DB_NAME already exists."
# else
#     log "Creating database $DB_NAME..."
    
#     # Create the database
#     mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -e "CREATE DATABASE $DB_NAME;" | tee -a "$LOG_FILE"
#     if [[ $? -ne 0 ]]; then
#         log "Failed to create database $DB_NAME."
#         exit 1
#     fi
# fi

# # Check if the table exists
# TABLE_EXISTS=$(mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -D"$DB_NAME" -e "SHOW TABLES LIKE 'users';" | grep "users" > /dev/null; echo "$?")
# if [[ $TABLE_EXISTS -eq 0 ]]; then
#     log "Table 'users' already exists in database $DB_NAME."
# else
#     log "Creating table 'users' in database $DB_NAME..."

#     # Create the table
#     mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -D"$DB_NAME" -e "
#     CREATE TABLE users (
#         id INT AUTO_INCREMENT PRIMARY KEY,
#         name VARCHAR(100),
#         email VARCHAR(100),
#         phone VARCHAR(20),
#         dob DATE,
#         gender VARCHAR(10),
#         address TEXT
#     );" | tee -a "$LOG_FILE"
#     if [[ $? -ne 0 ]]; then
#         log "Failed to create table 'users' in database $DB_NAME."
#         exit 1
#     fi

#     log "Table 'users' created successfully in database $DB_NAME."
# fi

# log "MySQL setup completed successfully."