#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker - Fully Automated Edition
############################################################

CONFIG_FILE="/root/proxy_mode.conf"
LOG_FILE="/root/Proxy.txt"
DEFAULT_PORT=3128

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Function to install Squid
install_squid() {
    echo "Checking if Squid is installed..."
    if ! command -v squid >/dev/null 2>&1; then
        echo "Squid is not installed. Installing now..."
        apt-get update -y && apt-get install squid apache2-utils -y
        if [ $? -eq 0 ]; then
            echo "Squid installed successfully."
        else
            echo "ERROR: Failed to install Squid. Please check your system settings."
            exit 1
        fi
    else
        echo "Squid is already installed."
    fi
}

# Detect all server IP addresses
detect_ips() {
    SERVER_IPS=$(hostname -I)
    if [ -z "$SERVER_IPS" ]; then
        echo "ERROR: Unable to detect server IPs. Please check your network configuration."
        exit 1
    else
        echo "Detected Server IPs: $SERVER_IPS"
    fi
}

# Function to generate a strong random password
generate_password() {
    tr -dc 'A-Za-z0-9@#%^&*()' </dev/urandom | head -c 16
}

# Function to create a proxy for a specific IP
create_proxy() {
    local ip=$1
    local username="bobby_$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)"
    local password=$(generate_password)

    echo "Creating proxy for IP: $ip on port $DEFAULT_PORT with username: $username"

    # Add user credentials to Squid
    if [ -f /etc/squid/passwd ]; then
        /usr/bin/htpasswd -b /etc/squid/passwd "$username" "$password"
    else
        /usr/bin/htpasswd -b -c /etc/squid/passwd "$username" "$password"
    fi

    # Log the credentials
    echo "$ip:$DEFAULT_PORT:$username:$password" >>"$LOG_FILE"
}

# Function to configure Squid for detected IPs
configure_squid() {
    echo "Configuring Squid with detected IPs..."

    # Backup original Squid configuration
    cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

    # Generate new Squid configuration
    cat >/etc/squid/squid.conf <<EOL
http_port $DEFAULT_PORT
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Proxy Authentication
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
EOL

    for ip in $SERVER_IPS; do
        echo "acl localnet src $ip" >>/etc/squid/squid.conf
    done

    # Restart Squid to apply changes
    systemctl restart squid
    echo "Squid configuration applied and service restarted."
}

# Main function to handle everything
main() {
    echo "Starting Bobby Bhai Proxy Maker..."
    install_squid
    detect_ips

    # Create proxies for all detected IPs
    for ip in $SERVER_IPS; do
        create_proxy "$ip"
    done

    # Configure and restart Squid
    configure_squid

    echo "All proxies have been created successfully!"
    echo "Proxy credentials have been saved to $LOG_FILE."
}

# Execute the main function
main
