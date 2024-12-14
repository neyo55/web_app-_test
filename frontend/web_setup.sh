#!/bin/bash

# web_setup.sh

# Set non-interactive mode to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Log all output to /var/log/web_setup.log
exec > /var/log/web_setup.log 2>&1

# Variables
NGINX_CONF="/etc/nginx/sites-available/web_app"
NGINX_CONF_LINK="/etc/nginx/sites-enabled/web_app"
DOMAIN_OR_IP="54.217.141.168"  # Update this with the actual DNS or IP
ERROR_PAGE="/usr/share/nginx/html/50x.html"
ADMINER_URL="https://www.adminer.org/latest.php"
ADMINER_FILE="/var/www/html/adminer.php"

# Function to create or update a file
create_or_update_file() {
    local file_path="$1"
    local file_content="$2"
    if [[ -f "$file_path" ]]; then
        echo "Updating $file_path..."
    else
        echo "Creating $file_path..."
    fi
    sudo bash -c "cat > $file_path" <<< "$file_content"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create or update $file_path" >&2
        exit 1
    fi
}

# Custom error page content
ERROR_PAGE_CONTENT='<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Server Error</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
        }
        h1 {
            font-size: 50px;
        }
        p {
            font-size: 20px;
        }
    </style>
</head>
<body>
    <h1>Oops!</h1>
    <p>Something went wrong on our end. Please try again later.</p>
</body>
</html>'

# Nginx configuration content
NGINX_CONF_CONTENT="server {
    listen 80;
    server_name $DOMAIN_OR_IP;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~ ^/adminer.php(/|$) {
        root /var/www/html;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }

    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}"

# Create or update the custom error page
create_or_update_file "$ERROR_PAGE" "$ERROR_PAGE_CONTENT"

# Create or update the Nginx configuration file
create_or_update_file "$NGINX_CONF" "$NGINX_CONF_CONTENT"

# Enable the Nginx site by creating a symlink if it doesn't exist
if [[ ! -L "$NGINX_CONF_LINK" ]]; then
    echo "Enabling the Nginx site..."
    sudo ln -s "$NGINX_CONF" "$NGINX_CONF_LINK"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to enable Nginx site" >&2
        exit 1
    fi
fi

# Download and place Adminer in the web directory
if [[ ! -f "$ADMINER_FILE" ]]; then
    echo "Downloading Adminer..."
    sudo wget "$ADMINER_URL" -O "$ADMINER_FILE"
    sudo chown www-data:www-data "$ADMINER_FILE"
    sudo chmod 755 "$ADMINER_FILE"
fi

# Test Nginx configuration and reload Nginx
echo "Testing Nginx configuration..."
sudo nginx -t
if [[ $? -ne 0 ]]; then
    echo "Error: Nginx configuration test failed" >&2
    exit 1
fi

sudo systemctl reload nginx
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to reload Nginx" >&2
    exit 1
fi

# Ensure PHP-FPM is installed and running
echo "Checking PHP-FPM status..."
if ! systemctl is-active --quiet php8.1-fpm; then
    echo "PHP-FPM is not running. Starting PHP-FPM..."
    sudo systemctl start php8.1-fpm
    sudo systemctl enable php8.1-fpm
else
    echo "PHP-FPM is already running."
fi

echo "Web layer setup complete."
