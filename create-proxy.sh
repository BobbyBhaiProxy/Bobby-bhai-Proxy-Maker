#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker with Fixed Port and IP Restriction
############################################################

CONFIG_FILE="/root/proxy_mode.conf"
LOG_FILE="/root/Proxy.txt"  # Changed log file name

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Detect the server's public IP address
SERVER_IP=$(curl -s ifconfig.me)
if [ -z "$SERVER_IP" ]; then
    echo "ERROR: Unable to detect the server IP. Please check your internet connection."
    exit 1
else
    echo "Detected Server IP: $SERVER_IP"
fi

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Function to generate random string
generate_random_string() {
    local length=$1
    tr -dc a-z0-9 </dev/urandom | head -c "$length"
}

# Function to test proxy
test_proxy() {
    local PROXY_IP=$1
    local USERNAME=$2
    local PASSWORD=$3
    local PORT=$4

    echo -ne "$PROXY_IP:$PORT:$USERNAME:$PASSWORD | Testing...."
    HTTP_STATUS=$(curl -x http://$USERNAME:$PASSWORD@$PROXY_IP:$PORT -s -o /dev/null --max-time 5 -w "%{http_code}" https://www.irctc.co.in)
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e " \033[32mWorking\033[0m"
        return 0
    else
        echo -e " \033[31mNot working (timeout or error)\033[0m"
        return 1
    fi
}

# Function to remove expired proxies
remove_expired_proxies() {
    while IFS= read -r line; do
        username=$(echo "$line" | awk -F ':' '{print $3}')  # Extract username from log entry
        validity=$(grep "$username" "$LOG_FILE" | awk '{print $6}')  # Assuming validity is stored at position 6
        
        # (Add your logic for checking expiry based on the validity)
        # This logic needs implementation based on your existing validity handling.
    done < "$LOG_FILE"
}

# Function to create a new proxy
create_proxy() {
    local proxy_count=$1
    local use_custom=$2
    local custom_username
    local custom_password

    # Default port for proxy
    custom_port=3128
    echo "Using default port 3128."

    # Loop to create the specified number of proxies
    for ((i=1; i<=proxy_count; i++)); do
        if [ "$use_custom" -eq 1 ]; then
            read -p "Enter username for Proxy User $i: " custom_username
            read -p "Enter password for Proxy User $i: " custom_password
            USERNAME="$custom_username"
            PASSWORD="$custom_password"
        else
            USERNAME=$(generate_random_string 8)
            PASSWORD=$(generate_random_string 12)
            echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"
        fi

        # Add user to Squid passwd file
        if [ -f /etc/squid/passwd ]; then
            /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
        else
            /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
        fi

        # Default validity is 31 days
        validity=31

        # Log the proxy with IP, PORT, USERNAME, and PASSWORD
        echo "$SERVER_IP:$custom_port:$USERNAME:$PASSWORD" >> "$LOG_FILE"

        # Test the proxy
        sleep 3
        test_proxy "$SERVER_IP" "$USERNAME" "$PASSWORD" "$custom_port"
    done
}

# Ask how many proxies to create
read -p "How many proxies do you want to create? " proxy_count
if [[ ! $proxy_count =~ ^[0-9]+$ ]] || [ "$proxy_count" -le 0 ]; then
    echo "Invalid number of proxies. Exiting."
    exit 1
fi

# Ask if user wants custom username and password
read -p "Do you want to use custom username and password? (yes/no): " custom_choice
if [[ "$custom_choice" == "yes" ]]; then
    use_custom=1
else
    use_custom=0
fi

create_proxy "$proxy_count" "$use_custom"  # Call to create proxies

# Reload Squid to apply changes
systemctl reload squid > /dev/null 2>&1

# Remove expired proxies after creating new ones
remove_expired_proxies

echo -e "\033[32mOperation completed. Check $LOG_FILE for details.\033[0m"
