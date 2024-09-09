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

# Ensure find-os script is available
/usr/bin/wget -q --no-check-certificate -O /usr/bin/sok-find-os https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/sok-find-os.sh
chmod 755 /usr/bin/sok-find-os

# Ensure create-proxy script is available
/usr/bin/wget -q --no-check-certificate -O /usr/bin/create-proxy https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/create-proxy.sh
chmod 755 /usr/bin/create-proxy

# Ensure squid-uninstall script is available
/usr/bin/wget -q --no-check-certificate -O /usr/bin/squid-uninstall https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid-uninstall.sh
chmod +x /usr/bin/squid-uninstall


# Check if Squid is already installed
if [[ -d /etc/squid/ ]]; then
    echo -e "\nSquid Proxy is already installed. Uninstalling the existing Squid Proxy...\n"
    # Run the squid-uninstall script
    /usr/bin/squid-uninstall
    if [ $? -ne 0 ]; then
        echo -e "\nERROR: Failed to uninstall Squid. Please check the uninstall script or manually uninstall Squid.\n"
        exit 1
    fi
    echo -e "\nExisting Squid Proxy removed. Proceeding with the new installation...\n"
fi

# Detect OS
SOK_OS=$(/usr/bin/sok-find-os)

# Check if the OS is supported
if [ $SOK_OS == "ERROR" ]; then
    cat /etc/*release
    echo -e "\nOS NOT SUPPORTED.\n"
    exit 1;
fi

# Proceed with Squid installation based on detected OS
echo -e "Installing Squid on ${SOK_OS}, please wait....\n"

if [ "$SOK_OS" == "ubuntu2404" ] || [ "$SOK_OS" == "ubuntu2204" ] || [ "$SOK_OS" == "ubuntu2004" ]; then
    apt update > /dev/null 2>&1
    apt -y install apache2-utils squid > /dev/null 2>&1
    touch /etc/squid/passwd
    wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/ubuntu-2204.conf
    iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1

elif [ "$SOK_OS" == "debian10" ] || [ "$SOK_OS" == "debian11" ] || [ "$SOK_OS" == "debian12" ]; then
    apt update > /dev/null 2>&1
    apt -y install apache2-utils squid > /dev/null 2>&1
    touch /etc/squid/passwd
    wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/debian12.conf
    iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1

elif [ "$SOK_OS" == "centos7" ] || [ "$SOK_OS" == "centos8" ] || [ "$SOK_OS" == "centos9" ] || [ "$SOK_OS" == "almalinux8" ] || [ "$SOK_OS" == "almalinux9" ]; then
    yum install squid httpd-tools wget -y > /dev/null 2>&1
    mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
    wget -q --no-check-certificate -O /etc/squid/squid.conf https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/conf/squid-centos7.conf
    iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
    systemctl enable squid > /dev/null 2>&1
    systemctl restart squid > /dev/null 2>&1

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
