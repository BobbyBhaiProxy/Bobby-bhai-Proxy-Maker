#!/bin/bash

############################################################
# Add Proxy Script
# Author: Bobby Bhai
############################################################

# Ensure the script is being run as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as user root or add sudo before command."
    exit 1
fi

# Source the main script to reuse functions
source /path/to/your/squid_proxy_manager.sh

# Function to create additional proxy users
create_proxies() {
    echo "How many proxies do you want to add?"
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

    # Start creating additional proxy users
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
    echo -e "\033[32mAdditional proxy users have been created and saved to $LOG_FILE\033[0m"
}

# Call the function to create additional proxies
create_proxies
