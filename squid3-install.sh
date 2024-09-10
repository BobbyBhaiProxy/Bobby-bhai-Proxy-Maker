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

# Function to clean up old installation files and logs
cleanup_old_files() {
    echo "Cleaning up old Squid installation files..."

    # Ensure we are cleaning files in the /root directory
    cd /root || exit

    # Remove old squid installation scripts and logs
    find /root -type f -name "squid3-install.sh.*" -exec rm -f {} \;
    rm -f /root/proxy_users.txt /root/proxy_users.log

    echo "Old Squid installation files cleaned."
}

# Function to download and install Squid Proxy
install_squid() {
    echo "Checking if Squid is already installed..."

    if [ -f /etc/squid/squid.conf ]; then
        echo "Squid is already installed. Skipping installation."
        return
    fi

    echo "Downloading and installing Squid Proxy..."
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt update > /dev/null 2>&1
        apt -y install apache2-utils squid > /dev/null 2>&1
    elif [[ "$OS" == "centos" || "$OS" == "almalinux" ]]; then
        yum install squid httpd-tools wget -y > /dev/null 2>&1
    else
        echo "Unsupported OS for Squid installation."
        exit 1
    fi

    if [ $? -ne 0 ]; then
        echo "ERROR: Squid installation failed. Please check the logs."
        exit 1
    fi

    echo "Squid installed successfully."
}

# Function to download supporting scripts (proxy creation, uninstall script)
download_supporting_scripts() {
    echo "Downloading necessary scripts..."

    # Download proxy creation script
    wget -q --no-check-certificate -O /usr/bin/create-proxy https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/create-proxy.sh
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to download create-proxy. Please check your internet connection or the URL."
        exit 1
    fi
    chmod 755 /usr/bin/create-proxy

    # Download Squid uninstall script (optional)
    wget -q --no-check-certificate -O /usr/bin/squid-uninstall https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid-uninstall.sh
    chmod +x /usr/bin/squid-uninstall
}

# Function to detect OS using /etc/os-release
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
        VERSION_ID=$(echo "$VERSION_ID" | tr -d '"')
    else
        echo "ERROR: OS detection failed. /etc/os-release not found."
        exit 1
    fi

    echo "Detected OS: $OS, Version: $VERSION_ID"
}

# Main installation process
detect_os

# Check if Squid is installed and running
if systemctl status squid > /dev/null 2>&1; then
    echo -e "\nSquid Proxy is already installed. Skipping installation."
else
    echo "Squid Proxy is not installed. Installing now..."
    install_squid
fi

# Download the supporting scripts
download_supporting_scripts

# Proceed with Squid configuration based on detected OS
echo -e "Configuring Squid on ${OS}, please wait....\n"

if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    touch /etc/squid/passwd
    wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/${OS}${VERSION_ID}.conf
    iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1

elif [[ "$OS" == "centos" || "$OS" == "almalinux" ]]; then
    touch /etc/squid/passwd
    mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
    wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/${OS}${VERSION_ID}.conf
    iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1

    # Add firewall rules for CentOS
    if [ -f /usr/bin/firewall-cmd ]; then
        firewall-cmd --zone=public --permanent --add-port=3128/tcp > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
    fi
else
    echo -e "OS NOT SUPPORTED by this script!"
    exit 1
fi

# Final message and logging
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${NC}"
echo -e "${GREEN}Squid Proxy successfully installed and configured on ${OS}.${NC}"
echo -e "${CYAN}To create proxy users, run the command: create-proxy${NC}"
echo -e "${NC}"
