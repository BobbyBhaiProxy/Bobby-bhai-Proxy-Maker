#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker - Fully Automated Edition
############################################################

LOG_FILE="/root/Proxy.txt"
DEFAULT_PORT=3128
IRCTC_URL="https://www.irctc.co.in/"

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Function to install Squid
install_squid() {
    echo "Installing Squid Proxy Server..."
    apt-get update -y && apt-get install squid apache2-utils curl -y
    if [ $? -eq 0 ]; then
        echo "Squid installed successfully."
    else
        echo "ERROR: Failed to install Squid. Please check your system settings."
        exit 1
    fi
}

# Generate a random username and password
generate_credentials() {
    username="bobby_$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)"
    password=$(tr -dc 'A-Za-z0-9@#%^&*()' </dev/urandom | head -c 16)
    echo "$username:$password"
}

# Create a single proxy
create_proxy() {
    credentials=$(generate_credentials)
    username=$(echo "$credentials" | cut -d: -f1)
    password=$(echo "$credentials" | cut -d: -f2)

    echo "Creating proxy with username: $username and password: $password"

    # Add user to Squid
    if [ -f /etc/squid/passwd ]; then
        htpasswd -b /etc/squid/passwd "$username" "$password"
    else
        htpasswd -b -c /etc/squid/passwd "$username" "$password"
    fi

    # Log the proxy details
    echo "127.0.0.1:$DEFAULT_PORT:$username:$password" >>"$LOG_FILE"
}

# Configure Squid with authentication and settings
configure_squid() {
    echo "Configuring Squid..."

    # Backup existing configuration
    cp /etc/squid/squid.conf /etc/squid/squid.conf.bak

    # Create a minimal configuration
    cat >/etc/squid/squid.conf <<EOL
http_port $DEFAULT_PORT
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Proxy Authentication
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
cache deny all
EOL

    # Restart Squid to apply the configuration
    systemctl restart squid
    echo "Squid configuration applied and service restarted."
}

# Test the proxy with IRCTC
test_proxy() {
    echo "Testing the proxy with IRCTC..."

    credentials=$(head -n 1 "$LOG_FILE")
    username=$(echo "$credentials" | cut -d: -f3)
    password=$(echo "$credentials" | cut -d: -f4)

    # Test proxy
    curl -x "http://127.0.0.1:$DEFAULT_PORT" -U "$username:$password" -I "$IRCTC_URL" -m 10 2>/dev/null | grep "HTTP/"
    if [ $? -eq 0 ]; then
        echo "Proxy is working with IRCTC!"
    else
        echo "Proxy test failed with IRCTC. Please check your configuration."
    fi
}

# Main function to handle everything
main() {
    echo "############################################################"
    echo " Bobby Bhai Proxy Maker - Fully Automated Edition"
    echo "############################################################"

    # Install Squid
    install_squid

    # Create the proxy
    create_proxy

    # Configure Squid
    configure_squid

    # Test the proxy
    test_proxy

    # Display proxy details
    echo "Proxy has been successfully created!"
    echo "Details saved in: $LOG_FILE"
    cat "$LOG_FILE"
}

# Run the script
main
