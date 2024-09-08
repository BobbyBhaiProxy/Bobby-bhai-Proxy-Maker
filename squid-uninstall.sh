#!/bin/bash

############################################################
# Squid Proxy Uninstaller - Bobby Bhai Proxy Maker
############################################################

# Check if the script is running as root
if [ `whoami` != root ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Ensure the OS detection script exists
if [ ! -f /usr/bin/sok-find-os ]; then
    echo "/usr/bin/sok-find-os not found"
    exit 1
fi

# Use sok-find-os to detect the OS
SOK_OS=$(/usr/bin/sok-find-os)

# Check if the OS is supported
if [ $SOK_OS == "ERROR" ]; then
    cat /etc/*release
    echo
    echo -e "\e[1;31m====================================================="
    echo -e "\e[1;31mOS NOT SUPPORTED"
    echo -e "\e[1;31m====================================================="
    echo -e "\e[0m"
    echo -e "Contact us to add support for your OS.\n"
    echo -e "https://github.com/BobbyBhaiProxy\n"
    exit 1
fi

# Uninstall Squid Proxy based on OS
if [ $SOK_OS == "ubuntu2404" ] || [ $SOK_OS == "ubuntu2204" ] || [ $SOK_OS == "ubuntu2004" ]; then
    /usr/bin/apt -y remove --purge squid squid-common squid-langpack
    rm -rf /etc/squid/
elif [ $SOK_OS == "ubuntu1804" ] || [ $SOK_OS == "ubuntu1604" ]; then
    /usr/bin/apt -y remove --purge squid3
    rm -rf /etc/squid/
elif [ $SOK_OS == "ubuntu1404" ]; then
    /usr/bin/apt remove --purge squid3 -y
    rm -rf /etc/squid3/ /etc/squid/
elif [[ $SOK_OS == debian* ]]; then
    echo "Uninstalling Squid Proxy on $SOK_OS"
    /usr/bin/apt -y remove --purge squid squid-common squid-langpack
    rm -rf /etc/squid/ /var/spool/squid
elif [[ $SOK_OS == centos* ]] || [[ $SOK_OS == almalinux* ]]; then
    yum remove squid -y || dnf remove squid -y
    rm -rf /etc/squid/
else
    echo "OS not supported for uninstallation."
    exit 1
fi

# Remove additional custom scripts
rm -f /usr/bin/squid-add-user /usr/bin/sok-find-os /usr/bin/squid-uninstall > /dev/null 2>&1

echo
echo "Squid Proxy uninstalled."
echo "Thank you for using Bobby Bhai Proxy Maker!"
echo "To reinstall Squid Proxy, visit https://github.com/BobbyBhaiProxy."
echo
