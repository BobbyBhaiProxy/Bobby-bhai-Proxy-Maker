#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker - Squid Installer
# Author: Your Name
# Github: https://github.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker
############################################################

# Define colors for success and error messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo -e "${RED}ERROR: You need to run the script as root or use sudo.${NC}"
    exit 1
fi

# Define installation directory
INSTALL_DIR="/root"

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
        echo -e "${RED}ERROR: Unsupported OS detected.${NC}"
        exit 1
    fi

    echo "Detected OS: $SOK_OS"
}

# Function to uninstall Squid
uninstall_squid() {
    echo -e "${RED}Uninstalling Squid Proxy...${NC}"
    if [ -f /usr/bin/squid-uninstall ]; then
        /usr/bin/squid-uninstall
        echo -e "${GREEN}Squid successfully uninstalled.${NC}"
    else
        echo "No uninstall script found, performing manual removal."
        if [[ "$SOK_OS" == *"ubuntu"* || "$SOK_OS" == *"debian"* ]]; then
            apt-get remove --purge squid -y
        elif [[ "$SOK_OS" == *"centos"* || "$SOK_OS" == *"almalinux"* || "$SOK_OS" == *"rockylinux"* ]]; then
            yum remove squid -y
        elif [[ "$SOK_OS" == *"fedora"* ]]; then
            dnf remove squid -y
        elif [[ "$SOK_OS" == *"archlinux"* ]]; then
            pacman -R squid --noconfirm
        elif [[ "$SOK_OS" == *"alpine"* ]]; then
            apk del squid
        elif [[ "$SOK_OS" == *"opensuse"* ]]; then
            zypper remove squid -y
        elif [[ "$SOK_OS" == *"freebsd"* || "$SOK_OS" == *"openbsd"* ]]; then
            pkg delete squid -y
        fi
        echo -e "${GREEN}Squid manually removed.${NC}"
    fi
}

# Function to install Squid based on detected OS
install_squid() {
    echo "Installing Squid Proxy..."

    case "$SOK_OS" in
        # Ubuntu versions
        "ubuntu2404"|"ubuntu2204"|"ubuntu2004"|"ubuntu1804"|"ubuntu1604")
            apt update > /dev/null 2>&1
            apt -y install apache2-utils squid > /dev/null 2>&1
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/ubuntu-2204.conf
            ;;

        # Debian versions
        "debian12")
            apt update > /dev/null 2>&1
            apt -y install apache2-utils squid > /dev/null 2>&1
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/debian12.conf
            ;;

        # CentOS/AlmaLinux/RockyLinux versions
        "centos7")
            yum install squid httpd-tools wget -y > /dev/null 2>&1
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-centos7.conf
            ;;
        "centos8"|"almalinux8"|"rockylinux8")
            yum install squid httpd-tools wget -y > /dev/null 2>&1
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-rockylinux.conf
            ;;
        "centos9"|"almalinux9"|"rockylinux9")
            yum install squid httpd-tools wget -y > /dev/null 2>&1
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-rockylinux.conf
            ;;

        # Fedora
        "fedora")
            dnf install squid httpd-tools wget -y > /dev/null 2>&1
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-fedora.conf
            ;;

        # Alpine Linux
        "alpine")
            apk add squid apache2-utils > /dev/null 2>&1
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-alpine.conf
            ;;

        # Arch Linux
        "archlinux")
            pacman -S squid apache-tools --noconfirm > /dev/null 2>&1
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-archlinux.conf
            ;;

        # openSUSE
        "opensuse15")
            zypper install squid apache2-utils -y > /dev/null 2>&1
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-opensuse15.conf
            ;;

        # FreeBSD/OpenBSD
        "freebsd")
            pkg install squid apache2-utils -y > /dev/null 2>&1
            wget -q --no-check-certificate -O /usr/local/etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-freebsd.conf
            ;;
        "openbsd")
            pkg_add squid apache2-utils > /dev/null 2>&1
            wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-openbsd.conf
            ;;

        # If OS is unsupported
        *)
            echo -e "${RED}ERROR: Unsupported OS for Squid installation. Exiting.${NC}"
            exit 1
            ;;
    esac

    # Apply basic firewall rules and enable Squid service
    iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1

    echo -e "${GREEN}Squid installed successfully.${NC}"
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

    echo -e "${GREEN}Scripts downloaded successfully.${NC}"
}

# Main logic to handle Squid installation, uninstallation, and proxy creation
main() {
    cleanup_old_files
    detect_os

    # Check if Squid is already installed
    if [ -f /etc/squid/squid.conf ]; then
        echo -e "${RED}Squid is already installed.${NC}"
        read -p "Do you want to uninstall and reinstall Squid? (y/n): " reinstall_choice

        if [[ "$reinstall_choice" == "y" || "$reinstall_choice" == "Y" ]]; then
            uninstall_squid
            install_squid
        else
            echo -e "${GREEN}To create proxies, use the command: create-proxy.${NC}"
            exit 0
        fi
    else
        install_squid
    fi

    download_scripts
    echo -e "${GREEN}Squid installation and setup completed.${NC}"
    echo -e "${GREEN}To create proxies, use the command: create-proxy.${NC}"
    echo -e "${GREEN}To uninstall Squid, use the command: sudo /usr/bin/squid-uninstall.${NC}"
}

# Run the main function
main
