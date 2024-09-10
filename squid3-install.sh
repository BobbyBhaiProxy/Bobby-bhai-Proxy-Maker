#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker
# Author: Your Name
# Github: https://github.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker
############################################################

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or use sudo."
    exit 1
fi

# Define installation directory and log file
INSTALL_DIR="/root"
LOG_FILE="/root/ProxyList.txt"
TARGET_URL="https://www.irctc.co.in"  # Replace with your target website

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Function to clean up old installation files
cleanup_old_files() {
    echo "Cleaning up old Squid installation files..."
    rm -f "$INSTALL_DIR/proxy_users.txt"
    rm -f "$INSTALL_DIR/proxy_users.log"
    echo "Old Squid installation files cleaned."
}

# Function to download and run the OS detection script (sok-find-os.sh)
detect_os() {
    OS_SCRIPT="/usr/bin/sok-find-os"
    
    # Download the OS detection script if it doesn't exist
    if [ ! -f "$OS_SCRIPT" ]; then
        echo "Downloading OS detection script..."
        wget -q --no-check-certificate -O "$OS_SCRIPT" https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/sok-find-os.sh
        chmod +x "$OS_SCRIPT"
    fi

    # Run the OS detection script
    SOK_OS=$($OS_SCRIPT)
    
    if [ "$SOK_OS" == "ERROR" ]; then
        echo "Unsupported OS detected."
        exit 1
    fi

    echo "Detected OS: $SOK_OS"
}

# Function to uninstall Squid
uninstall_squid() {
    echo "Uninstalling Squid Proxy..."
    if [ -f /usr/bin/squid-uninstall ]; then
        /usr/bin/squid-uninstall
        echo "Squid successfully uninstalled."
    else
        echo "No uninstall script found, performing manual removal."
        if [[ "$SOK_OS" == "ubuntu" || "$SOK_OS" == "debian" ]]; then
            apt-get remove --purge squid -y
        elif [[ "$SOK_OS" == "centos" || "$SOK_OS" == "almalinux" ]]; then
            yum remove squid -y
        fi
        echo "Squid manually removed."
    fi
}

# Function to install Squid based on detected OS
install_squid() {
    echo "Installing Squid Proxy..."
    
    # Check for the existence of Squid
    if [ -f /etc/squid/squid.conf ]; then
        echo "Squid is already installed. Skipping installation."
        return
    fi

    # Install Squid based on detected OS
    if [[ "$SOK_OS" == "ubuntu2404" || "$SOK_OS" == "ubuntu2204" || "$SOK_OS" == "ubuntu2004" || "$SOK_OS" == "debian10" || "$SOK_OS" == "debian11" || "$SOK_OS" == "debian12" ]]; then
        apt update > /dev/null 2>&1
        apt -y install apache2-utils squid > /dev/null 2>&1
        touch /etc/squid/passwd
    elif [[ "$SOK_OS" == "centos7" || "$SOK_OS" == "centos8" || "$SOK_OS" == "centos9" || "$SOK_OS" == "almalinux8" || "$SOK_OS" == "almalinux9" ]]; then
        yum install squid httpd-tools wget -y > /dev/null 2>&1
        mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
    else
        echo "Unsupported OS for Squid installation. Exiting."
        exit 1
    fi

    # Finalize Squid installation
    wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid.conf
    iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1

    echo "Squid installed successfully."
}

# Function to download proxy creation script and uninstall script
download_scripts() {
    echo "Downloading proxy creation and uninstall scripts..."
    
    # Download proxy creation script
    if [ ! -f /usr/bin/create-proxy ]; then
        wget -q --no-check-certificate -O /usr/bin/create-proxy https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/create-proxy.sh
        chmod +x /usr/bin/create-proxy
    fi

    # Download Squid uninstall script
    if [ ! -f /usr/bin/squid-uninstall ]; then
        wget -q --no-check-certificate -O /usr/bin/squid-uninstall https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid-uninstall.sh
        chmod +x /usr/bin/squid-uninstall
    fi

    echo "Scripts downloaded successfully."
}

# Function to create proxy users
create_proxy() {
    echo "Proxy creation started..."

    # Get the server's public IP
    SERVER_IP=$(curl -s ifconfig.me)

    # Get the current time in Indian Standard Time (IST) and 12-hour format
    CURRENT_TIME=$(TZ='Asia/Kolkata' date +"%I:%M %p %d-%m-%Y")

    # Add a header to the log file with the date and time of proxy creation
    echo -e "\nThis set of proxies was created at $CURRENT_TIME (IST)\n" >> "$LOG_FILE"

    # Ask user for the mode (Manual or Automatic)
    read -p "Select Mode (M for Manual, A for Automatic): " mode_choice

    if [[ "$mode_choice" == "M" || "$mode_choice" == "m" ]]; then
        # Manual input mode
        read -p "Enter Proxy username: " USERNAME
        read -p "Enter Proxy password: " PASSWORD

        # Add the user to Squid
        htpasswd -b /etc/squid/passwd "$USERNAME" "$PASSWORD"

        # Test and log the proxy
        test_and_log_proxy "$SERVER_IP" "$USERNAME" "$PASSWORD"

    elif [[ "$mode_choice" == "A" || "$mode_choice" == "a" ]]; then
        # Automatic mode
        read -p "How many proxies do you want to create? " proxy_count

        if ! [[ "$proxy_count" =~ ^[0-9]+$ ]] || [ "$proxy_count" -le 0 ]; then
            echo "Invalid number. Exiting."
            exit 1
        fi

        for ((i=1; i<=proxy_count; i++)); do
            USERNAME="user$(tr -dc a-z0-9 </dev/urandom | head -c 6)"
            PASSWORD="pass$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)"

            # Add the user to Squid
            htpasswd -b /etc/squid/passwd "$USERNAME" "$PASSWORD"

            # Test and log the proxy
            test_and_log_proxy "$SERVER_IP" "$USERNAME" "$PASSWORD"

            # Simulate delay for each proxy creation
            sleep 3
        done
    else
        echo "Invalid mode selected. Exiting."
        exit 1
    fi

    # Reload Squid to apply changes
    systemctl reload squid > /dev/null 2>&1
    echo "Proxies created and tested successfully."
}

# Function to test proxies and log the result (with a 5-second timeout)
test_and_log_proxy() {
    local PROXY_IP=$1
    local USERNAME=$2
    local PASSWORD=$3

    # Display testing message
    echo -ne "$PROXY_IP:3128:$USERNAME:$PASSWORD | Testing..."

    # Test the proxy by connecting to the target website with a 5-second timeout
    HTTP_STATUS=$(curl -x "http://$USERNAME:$PASSWORD@$PROXY_IP:3128" -s -o /dev/null -w "%{http_code}" --max-time 5 "$TARGET_URL")

    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e " | ${GREEN}Working${NC}"
        echo "$PROXY_IP:3128:$USERNAME:$PASSWORD" >> "$LOG_FILE"
    else
        echo -e " | ${RED}Not Working${NC}"
    fi
}

# Main script logic
cleanup_old_files
detect_os
install_squid
download_scripts

echo -e "Squid installation and setup completed."
echo -e "To create proxies, use the command: create-proxy."
echo -e "To uninstall Squid, use the command: sudo /usr/bin/squid-uninstall."
