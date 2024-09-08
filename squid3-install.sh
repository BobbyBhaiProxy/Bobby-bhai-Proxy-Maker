#!/bin/bash

############################################################
# Squid Proxy Installer with Enhanced Proxy Generation and Squid Detection
# Author: Bobby Bhai
############################################################

# Ensure the script is being run as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as user root or add sudo before command."
    exit 1
fi

# Function to check if Squid is already installed
check_squid_installed() {
    if command -v squid >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to detect OS and install Squid
install_squid() {
    echo "Detecting OS..."

    if grep -q "Ubuntu" /etc/os-release; then
        echo "Installing Squid on Ubuntu..."
        sudo apt update > /dev/null 2>&1
        sudo apt -y install squid > /dev/null 2>&1
    elif grep -q "Debian" /etc/os-release; then
        echo "Installing Squid on Debian..."
        sudo apt update > /dev/null 2>&1
        sudo apt -y install squid > /dev/null 2>&1
    elif grep -q "CentOS" /etc/os-release; then
        echo "Installing Squid on CentOS..."
        sudo yum install squid -y > /dev/null 2>&1
    elif grep -q "AlmaLinux" /etc/os-release; then
        echo "Installing Squid on AlmaLinux..."
        sudo yum install squid -y > /dev/null 2>&1
    else
        echo "OS not supported."
        exit 1
    fi

    echo "Squid installation successful."
    systemctl enable squid
    systemctl restart squid
}

# Function to generate random usernames and passwords
generate_random_string() {
    local length=$1
    echo $(tr -dc A-Za-z0-9 </dev/urandom | head -c ${length} ; echo '')
}

# Function to create proxy users
create_proxies() {
    echo "How many proxies do you want to create?"
    read USER_COUNT

    # Validate the user count
    if [[ ! $USER_COUNT =~ ^[0-9]+$ ]] || [ $USER_COUNT -le 0 ]; then
        echo "Invalid number of users. Exiting."
        exit 1
    fi

    # IP Series Selection for X-Forwarded-For header
    echo "Select an IP series for spoofing the X-Forwarded-For header:"
    echo "1. 103.15"
    echo "2. 172.232"
    echo "3. 139.84"
    echo "4. 157.33"
    echo "5. 103.157"
    echo "6. 103.18"
    echo "7. 103.161"
    echo "8. 210.89"
    read -p "Enter the number corresponding to your choice: " IP_CHOICE

    # Set IP Prefix based on selection
    case $IP_CHOICE in
        1) SELECTED_IP_PREFIX="103.15" ;;
        2) SELECTED_IP_PREFIX="172.232" ;;
        3) SELECTED_IP_PREFIX="139.84" ;;
        4) SELECTED_IP_PREFIX="157.33" ;;
        5) SELECTED_IP_PREFIX="103.157" ;;
        6) SELECTED_IP_PREFIX="103.18" ;;
        7) SELECTED_IP_PREFIX="103.161" ;;
        8) SELECTED_IP_PREFIX="210.89" ;;
        *) echo "Invalid selection"; exit 1 ;;
    esac

    echo "Selected IP Prefix: $SELECTED_IP_PREFIX"

    # Define the log file path with timestamp
    LOG_FILE="/root/proxy_users_$(date +%F_%T).txt"

    # Create a new log file
    touch "$LOG_FILE"

    # Start creating proxy users
    for ((i=1;i<=USER_COUNT;i++)); do
        USERNAME=$(generate_random_string 8)
        PASSWORD=$(generate_random_string 12)

        echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"

        # Generate IP address
        OCTET=$(shuf -i 1-254 -n 1)
        SPOOFED_IP="${SELECTED_IP_PREFIX}.$OCTET"

        echo "Generated Spoofed IP: $SPOOFED_IP for User $USERNAME"

        # Add user to Squid password file
        if [ ! -f /etc/squid/passwd ]; then
            echo "Creating new /etc/squid/passwd file"
            htpasswd -cb /etc/squid/passwd $USERNAME $PASSWORD
        else
            echo "Adding user to /etc/squid/passwd"
            htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
        fi

        # Append user and IP details to Squid config
        echo "Adding proxy user $USERNAME and IP $SPOOFED_IP to squid.conf"
        echo -e "acl user$i proxy_auth $USERNAME\nheader_access X-Forwarded-For allow user$i\nrequest_header_add X-Forwarded-For \"$SPOOFED_IP\" user$i" >> /etc/squid/squid.conf

        # Log generated proxy details in the log file
        echo "$SPOOFED_IP:3128:$USERNAME:$PASSWORD" >> "$LOG_FILE"
        echo "Proxy details logged for $USERNAME"
    done

    # Restart Squid service
    echo "Restarting Squid to apply changes..."
    systemctl restart squid
    if [ $? -eq 0 ]; then
        echo "Squid restarted successfully."
    else
        echo "ERROR: Failed to restart Squid service."
        exit 1
    fi

    # Display the log file location
    echo -e "\033[32mProxy users have been created and saved to $LOG_FILE\033[0m"
}

# Main control flow
if check_squid_installed; then
    echo "Squid is already installed."
    read -p "Do you want to create proxies? (1. Yes / 2. No): " PROXY_CHOICE
    if [[ "$PROXY_CHOICE" == "1" ]]; then
        create_proxies
    else
        echo "Exiting script."
        exit 0
    fi
else
    echo "Squid not found, installing..."
    install_squid
    create_proxies
fi
