#!/bin/bash

############################################################
# Squid Proxy Installation and Management Script
# This script will clean old configurations before installing a new Squid proxy
############################################################

# Paths and file locations
LOG_FILE="/root/Proxy.txt"
EXPIRED_LOG_FILE="/root/expired_proxies.txt"
PROXY_CONFIG_DIR="/etc/squid"
SQUAD_LOG_DIR="/var/log/squid"

# Function to clean up old proxy configurations and files
clean_up_old_configs() {
    echo "Cleaning up old configurations and files..."

    # Remove Squid configuration if it exists
    if [ -d "$PROXY_CONFIG_DIR" ]; then
        rm -rf "$PROXY_CONFIG_DIR"
        echo "Removed Squid configuration directory."
    fi

    # Remove Squid log files if they exist
    if [ -d "$SQUAD_LOG_DIR" ]; then
        rm -rf "$SQUAD_LOG_DIR"
        echo "Removed Squid log directory."
    fi

    # Remove previous proxy log files
    if [ -f "$LOG_FILE" ]; then
        rm "$LOG_FILE"
        echo "Removed previous proxy log file."
    fi

    if [ -f "$EXPIRED_LOG_FILE" ]; then
        rm "$EXPIRED_LOG_FILE"
        echo "Removed previous expired proxy log file."
    fi

    # Remove any old Squid installation (clean and purge)
    if command -v squid &> /dev/null; then
        echo "Removing old Squid installation..."
        apt remove --purge -y squid
        apt autoremove -y
        echo "Old Squid installation removed."
    fi
}

# Function to detect OS and install Squid Proxy
install_squid() {
    # Detect OS and install Squid Proxy
    if command -v squid &> /dev/null; then
        echo "Squid Proxy is already installed."
    else
        echo "Installing Squid Proxy..."
        # For Ubuntu/Debian-based systems
        apt update
        apt install -y squid
        systemctl enable squid
        systemctl start squid
        echo "Squid Proxy installed and started."
    fi
}

# Function to create a proxy user
create_proxy() {
    echo "Starting proxy creation..."

    # Ask for the number of proxies to create (max 4 in slot IP, max 2 in dedicated IP mode)
    read -p "How many proxies do you want to create? (1-3): " proxy_count

    if [ "$proxy_count" -le 0 ] || [ "$proxy_count" -gt 3 ]; then
        echo "ERROR: You can only create between 1 and 3 proxies at a time."
        exit 1
    fi

    # Ask for IP restriction mode
    read -p "Choose IP restriction mode (Slot IP or Dedicated IP): " ip_mode

    # IP mode validation
    if [[ "$ip_mode" != "Slot IP" && "$ip_mode" != "Dedicated IP" ]]; then
        echo "ERROR: Invalid IP restriction mode."
        exit 1
    fi

    # Ask for the custom port (default 3128)
    read -p "Enter the custom port for the proxy (default 3128): " custom_port
    if [ -z "$custom_port" ]; then
        custom_port="3128"
    fi

    # Ask for username and password
    for ((i=1; i<=proxy_count; i++)); do
        read -p "Enter username for Proxy $i: " USERNAME
        read -p "Enter password for Proxy $i: " PASSWORD

        # Get the server's internal IP address
        IP=$(hostname -I | awk '{print $1}')
        # Log proxy details to file
        echo "$IP:$custom_port:$USERNAME:$PASSWORD" >> "$LOG_FILE"

        # Display proxy info
        echo "Proxy $i created: $IP:$custom_port:$USERNAME:$PASSWORD"
    done

    echo "All proxies created and logged in $LOG_FILE."
}

# Function to manage expired proxies
check_expired_proxies() {
    echo "Checking expired proxies..."

    current_date=$(date +%s)

    while IFS=: read -r IP PORT USERNAME PASSWORD; do
        # Calculate the expiry date (30 days from now)
        expiry_date=$(stat --format=%Y "$LOG_FILE" | awk -v days=2592000 '{print $1 + days}')

        if [ "$current_date" -gt "$expiry_date" ]; then
            echo "Removing expired proxy: $IP:$PORT:$USERNAME:$PASSWORD"
            echo "$IP:$PORT:$USERNAME:$PASSWORD" >> "$EXPIRED_LOG_FILE"
            # Remove the proxy from the log
            sed -i "/$IP:$PORT:$USERNAME:$PASSWORD/d" "$LOG_FILE"
        fi
    done < "$LOG_FILE"

    echo "Expired proxies have been logged in $EXPIRED_LOG_FILE."
}

# Main function to execute the script
main() {
    # Clean up old configurations and files before installing new Squid Proxy
    clean_up_old_configs

    # Install Squid Proxy
    install_squid

    # Ask for action
    echo "Choose an action:"
    echo "1. Create Proxy Users"
    echo "2. Check and Remove Expired Proxies"
    read -p "Enter your choice: " choice

    case "$choice" in
        1)
            create_proxy
            ;;
        2)
            check_expired_proxies
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}

# Run the main function
main
