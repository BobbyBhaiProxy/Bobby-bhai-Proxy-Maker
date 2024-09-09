#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker
# Author: Your Name
# Github: https://github.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker
############################################################

# Check if the script is running as root
if [ `whoami` != root ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Function to clean up old installation files and logs
cleanup_old_files() {
    echo "Cleaning up old Squid installation files..."

    # Ensure we are cleaning files in the /root directory
    cd /root

    # Remove any old squid installation scripts and logs
    find /root -type f -name "squid3-install.sh.*" -exec rm -f {} \;
    rm -f /root/proxy_users.txt
    rm -f /root/proxy_users.log

    echo "Old Squid installation files cleaned."
}

# Function to download and run the installation script
install_squid() {
    echo "Downloading and installing Squid Proxy..."
    wget https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid3-install.sh -O squid3-install.sh
    sudo bash squid3-install.sh
}

# Function to download the supporting scripts (OS detection, proxy creation, uninstall script)
download_supporting_scripts() {
    echo "Downloading necessary scripts..."

    # Download OS detection script
    if ! /usr/bin/wget -q --no-check-certificate -O /usr/bin/sok-find-os https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/sok-find-os.sh; then
        echo "ERROR: Failed to download sok-find-os. Please check your internet connection or the URL."
        exit 1
    fi
    chmod 755 /usr/bin/sok-find-os

    # Download proxy creation script
    /usr/bin/wget -q --no-check-certificate -O /usr/bin/create-proxy https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/create-proxy.sh
    chmod 755 /usr/bin/create-proxy

    # Download Squid uninstall script
    /usr/bin/wget -q --no-check-certificate -O /usr/bin/squid-uninstall https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid-uninstall.sh
    chmod +x /usr/bin/squid-uninstall
}

# Check if Squid is already installed
if [[ -d /etc/squid/ ]]; then
    echo -e "\nSquid Proxy is already installed."

    # Ask the user if they want to reinstall Squid
    read -p "Do you want to uninstall and reinstall Squid? (y/n): " reinstall_choice

    if [[ "$reinstall_choice" == "y" || "$reinstall_choice" == "Y" ]]; then
        echo "Uninstalling Squid..."
        
        # Automatically run the squid-uninstall command
        sudo squid-uninstall

        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to uninstall Squid. Please manually check the uninstall process."
            exit 1
        fi

        echo "Squid uninstalled successfully."

        # Clean up old files before reinstalling
        cleanup_old_files

        # Download and run the new installation script
        install_squid
        exit 0
    else
        echo "Exiting without reinstalling Squid."
        exit 0
    fi
else
    # If Squid is not installed, download and install Squid
    echo "Squid Proxy is not installed. Installing now..."
    install_squid
    exit 0
fi

# Download supporting scripts (OS detection, proxy creation, uninstall script)
download_supporting_scripts

# Detect the OS using the sok-find-os script
SOK_OS=$(/usr/bin/sok-find-os)

# Check if the OS is supported
if [ "$SOK_OS" == "ERROR" ]; then
    cat /etc/*release
    echo -e "\nOS NOT SUPPORTED.\n"
    exit 1
fi

# Proceed with Squid installation based on detected OS
echo -e "Installing Squid on ${SOK_OS}, please wait....\n"

if [[ "$SOK_OS" == "ubuntu2404" || "$SOK_OS" == "ubuntu2204" || "$SOK_OS" == "ubuntu2004" ]]; then
    apt update > /dev/null 2>&1
    apt -y install apache2-utils squid > /dev/null 2>&1
    touch /etc/squid/passwd
    wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/ubuntu-2204.conf
    iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1

elif [[ "$SOK_OS" == "debian10" || "$SOK_OS" == "debian11" || "$SOK_OS" == "debian12" ]]; then
    apt update > /dev/null 2>&1
    apt -y install apache2-utils squid > /dev/null 2>&1
    touch /etc/squid/passwd
    wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/debian12.conf
    iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1

elif [[ "$SOK_OS" == "centos7" || "$SOK_OS" == "centos8" || "$SOK_OS" == "centos9" || "$SOK_OS" == "almalinux8" || "$SOK_OS" == "almalinux9" ]]; then
    yum install squid httpd-tools wget -y > /dev/null 2>&1
    mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
    wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-centos7.conf
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
echo -e "${GREEN}Squid Proxy successfully installed on ${SOK_OS}.${NC}"
echo -e "${CYAN}To create proxy users, run command: create-proxy${NC}"
echo -e "${NC}"
