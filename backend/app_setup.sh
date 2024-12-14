#!/bin/bash

# app_setup.sh

# Set non-interactive mode to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Log all output to /var/log/app_setup.log
exec > /var/log/app_setup.log 2>&1

# Variables
APP_DIR="/home/ubuntu/project-directory/backend"  # Update with the actual application directory
ENV_FILE="$APP_DIR/.env"  
SERVICE_NAME="web_app"
GUNICORN_CONFIG="$APP_DIR/gunicorn_config.py"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Exit the script if a command fails
exit_script() {
    log "Error: $1"
    exit 1
}

# Load environment variables from .env file
if [[ -f "$ENV_FILE" ]]; then
    log "Loading environment variables from $ENV_FILE..."
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ ! $line =~ ^# && $line == *=* ]]; then
            export "$line"
        fi
    done < "$ENV_FILE"
else
    log ".env file not found in $APP_DIR."
    exit 1
fi

# Function to install Gunicorn
install_gunicorn() {
    log "Checking for Gunicorn installation..."
    GUNICORN_PATH=$(which gunicorn)
    if [[ -z "$GUNICORN_PATH" ]]; then
        log "Gunicorn not found in PATH, attempting installation..."
        sudo pip3 install gunicorn || exit_script "Failed to install Gunicorn."
        GUNICORN_PATH=$(which gunicorn)
        if [[ -z "$GUNICORN_PATH" ]]; then
            exit_script "Gunicorn installation failed or not found, cannot proceed."
        fi
    else
        log "Gunicorn is already installed."
    fi
}

# Function to set up the Gunicorn service
setup_gunicorn_service() {
    log "Setting up Gunicorn service..."
    GUNICORN_PATH=$(which gunicorn)
    if [[ -z "$GUNICORN_PATH" ]]; then
        exit_script "Gunicorn path not found, cannot proceed."
    fi

    SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
    sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Gunicorn instance to serve the web application
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=$APP_DIR
ExecStart=$GUNICORN_PATH -c $GUNICORN_CONFIG app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    # Ensure correct permissions for the service file
    sudo chown root:root /etc/systemd/system/$SERVICE_NAME.service || exit_script "Failed to set ownership of the service file."
    sudo chmod 644 /etc/systemd/system/$SERVICE_NAME.service || exit_script "Failed to set permissions of the service file."

    # Ensure correct permissions for the application directory
    sudo chown -R ubuntu:www-data $APP_DIR || exit_script "Failed to set ownership of $APP_DIR."
    sudo chmod -R 755 $APP_DIR || exit_script "Failed to set permissions of $APP_DIR."

    log "Configured Gunicorn systemd service file."

    # Reload systemd, enable, and restart the Gunicorn service
    sudo systemctl daemon-reload || exit_script "Failed to reload systemd."
    sudo systemctl enable $SERVICE_NAME || exit_script "Failed to enable $SERVICE_NAME."
    sudo systemctl restart $SERVICE_NAME || exit_script "Failed to restart $SERVICE_NAME."

    log "Gunicorn service $SERVICE_NAME started and enabled on boot."
}

log "Starting application setup..."

# Install Gunicorn
install_gunicorn

# Verify Gunicorn configuration file exists
if [[ ! -f "$GUNICORN_CONFIG" ]]; then
    exit_script "Gunicorn configuration file $GUNICORN_CONFIG not found."
fi

# Set up the Gunicorn service
setup_gunicorn_service

log "Application layer setup complete."