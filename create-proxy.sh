#!/bin/bash

############################################################
# Fully Automated Proxy Maker - Bobby Bhai
############################################################

CONFIG_FILE="/root/proxy_mode.conf"
LOG_FILE="/root/proxy.txt"
DEFAULT_PORT="3128"

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Function to install dependencies
install_dependencies() {
    echo "Installing required dependencies..."
    apt update -y && apt install -y squid apache2-utils curl
    echo "Dependencies installed successfully."
}

# Detect the server's public IP
detect_server_ip() {
    echo "Detecting server IP..."
    SERVER_IP=$(curl -s ifconfig.me)
    if [ -z "$SERVER_IP" ]; then
        echo "ERROR: Unable to detect the server IP. Please check your internet connection."
        exit 1
    else
        echo "Detected Server IP: $SERVER_IP"
    fi
}

# Function to generate random string
generate_random_string() {
    local length=$1
    tr -dc a-z0-9 </dev/urandom | head -c "$length"
}

# Function to create a single proxy
create_proxy() {
    echo "Creating proxy..."

    # Generate random username and password
    USERNAME=$(generate_random_string 8)
    PASSWORD=$(generate_random_string 12)

    # Add user to Squid passwd file
    if [ -f /etc/squid/passwd ]; then
        /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
    else
        /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
    fi

    # Log the proxy details
    echo "$SERVER_IP:$DEFAULT_PORT:$USERNAME:$PASSWORD $(date '+%d-%m-%y') 31" >> "$LOG_FILE"
    echo "Proxy created with Username: $USERNAME and Password: $PASSWORD"
}

# Function to test proxy
test_proxy() {
    echo -ne "Testing proxy..."
    HTTP_STATUS=$(curl -x http://$USERNAME:$PASSWORD@$SERVER_IP:$DEFAULT_PORT -s -o /dev/null --max-time 5 -w "%{http_code}" https://www.irctc.co.in)
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e " \033[32mWorking\033[0m"
        echo "Test Status: Working" >> "$LOG_FILE"
    else
        echo -e " \033[31mNot working\033[0m"
        echo "Test Status: Not working" >> "$LOG_FILE"
    fi
}

# Function to reload Squid
reload_squid() {
    echo "Reloading Squid to apply changes..."
    systemctl reload squid > /dev/null 2>&1
    echo "Squid reloaded successfully."
}

# Main script execution
install_dependencies
detect_server_ip
create_proxy
reload_squid
test_proxy

echo -e "\033[32mProxy successfully created and logged in $LOG_FILE.\033[0m"
