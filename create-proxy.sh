#!/bin/bash

############################################################
# Create Proxy Script - Bobby Bhai Proxy Maker
# Author: Your Name
############################################################

# Ensure the script is being run as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Function to generate random strings (for username and password)
generate_random_string() {
    LENGTH=$1
    tr -dc A-Za-z0-9 </dev/urandom | head -c $LENGTH
}

# Function to create additional proxy users
create_proxies() {
    echo "How many proxies do you want to add?"
    read USER_COUNT

    # Validate the user count
    if [[ ! $USER_COUNT =~ ^[0-9]+$ ]] || [ $USER_COUNT -le 0 ]; then
        echo "Invalid number of users. Exiting."
        exit 1
    fi

    # Ask user for the starting two series of the IP
    echo "Enter the first two segments of your desired IP (e.g., 172.232, 103.15):"
    read -p "IP series: " SELECTED_IP_PREFIX

    # Validate IP format (basic validation, ensuring two segments separated by a dot)
    if [[ ! $SELECTED_IP_PREFIX =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid IP format. Please provide in format 'xxx.xxx'. Exiting."
        exit 1
    fi

    echo "Selected IP Prefix: $SELECTED_IP_PREFIX"

    # Define the log file path with timestamp
    LOG_FILE="/root/proxy_users_$(date +%F_%T).txt"
    touch "$LOG_FILE"

    # Start creating additional proxy users
    for ((i=1;i<=USER_COUNT;i++)); do
        USERNAME=$(generate_random_string 8)
        PASSWORD=$(generate_random_string 12)

        echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"

        # Generate IP address
        OCTET1=$(shuf -i 1-254 -n 1)
        OCTET2=$(shuf -i 1-254 -n 1)
        SPOOFED_IP="${SELECTED_IP_PREFIX}.$OCTET1.$OCTET2"

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
        echo -e "acl user$i proxy_auth $USERNAME\nheader_access X-Forwarded-For allow user$i\nrequest_header_add X-Forwarded-For \"$SPOOFED_IP\" user$i" >> /etc/squid/squid.conf

        # Log generated proxy details in the log file
        echo "$SPOOFED_IP:3128:$USERNAME:$PASSWORD" >> "$LOG_FILE"
        echo "Proxy details logged for $USERNAME"
    done

    # Restart Squid service to apply changes
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

# Call the function to create additional proxies
create_proxies
