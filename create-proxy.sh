#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker with Fixed Port and IP Restriction
############################################################

CONFIG_FILE="/root/proxy_mode.conf"
LOG_FILE="/root/${SERVER_IP}.txt"

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

# Function to count existing proxies in the log
count_existing_proxies() {
    grep -c "$SERVER_IP" "$LOG_FILE"
}

# Function to check for additional IPs on the server
check_additional_ips() {
    ip -4 addr show | grep inet | grep -v "$SERVER_IP" | grep -v '127.0.0.1' | wc -l
}

# Function to remove expired proxies
remove_expired_proxies() {
    while IFS= read -r line; do
        creation_date=$(echo "$line" | awk '{print $5}')  # Assuming date is stored at position 5 in log format
        username=$(echo "$line" | awk -F ':' '{print $3}')  # Extract username from log entry

        creation_timestamp=$(date -d "$creation_date" +%s 2>/dev/null)
        if [ -z "$creation_timestamp" ];then
            echo "ERROR: Invalid date format in log file: $creation_date"
            continue
        fi
        
        days_diff=$(( ( $(date +%s) - $creation_timestamp ) / 86400 ))

        # Remove the proxy if expired (custom logic for 31 days for new or specified days for replacement)
        validity=$(grep "$username" "$LOG_FILE" | awk '{print $6}')  # Assuming validity is stored at position 6
        if [ "$days_diff" -ge "$validity" ]; then
            echo "Proxy $username has expired. Removing it from the server."
            /usr/bin/htpasswd -D /etc/squid/passwd "$username"
            sed -i "/$username/d" "$LOG_FILE"
            echo "$(date '+%d-%m-%y %I:%M %p') - Proxy $username has been removed (Expired after $validity days)." >> "$LOG_FILE"
        fi
    done < "$LOG_FILE"
}

# Function to initialize or check the proxy mode
initialize_or_check_mode() {
    if [ -f "$CONFIG_FILE" ]; then
        stored_mode=$(cat "$CONFIG_FILE")
        if [ "$stored_mode" -ne "$ip_restriction" ]; then
            echo "ERROR: Proxy mode has already been set to $stored_mode. You cannot switch modes."
            exit 1
        fi
    else
        echo "$ip_restriction" > "$CONFIG_FILE"
    fi
}

# Function to create a new or replacement proxy
create_proxy() {
    local proxy_count=$1
    local is_replacement=$2

    # Default port for proxy
    custom_port=3128
    echo "Using default port 3128."

    # Loop to create or replace the specified number of proxies
    for ((i=1; i<=proxy_count; i++)); do
        USERNAME=$(generate_random_string 8)
        PASSWORD=$(generate_random_string 12)
        echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"

        # Add user to Squid passwd file
        if [ -f /etc/squid/passwd ]; then
            /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
        else
            /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
        fi

        # Determine validity: 31 days for new proxies, or custom validity for replacements
        if [ "$is_replacement" -eq 1 ]; then
            read -p "Enter the custom validity (number of days) for Proxy User $USERNAME: " validity
            if [[ ! $validity =~ ^[0-9]+$ ]]; then
                echo "Invalid input. Please enter a valid number of days."
                validity=31  # Default to 31 if invalid input
            fi
        else
            validity=31  # Default to 31 days for new proxies
        fi

        # Log the proxy with creation date and validity
        echo "$SERVER_IP:$custom_port:$USERNAME:$PASSWORD $(date '+%d-%m-%y') $validity" >> "$LOG_FILE"

        # Test the proxy
        sleep 3
        test_proxy "$SERVER_IP" "$USERNAME" "$PASSWORD" "$custom_port"
    done
}

# Ask if user wants new or replacement proxy
echo "Do you want to create a new proxy or replace an existing one?"
echo "1. New Proxy (Default 31 days validity)"
echo "2. Replace Existing Proxy (Custom validity)"
read -p "Enter your choice (1 for New, 2 for Replace): " proxy_action

if [ "$proxy_action" -ne 1 ] && [ "$proxy_action" -ne 2 ]; then
    echo "Invalid choice. Exiting."
    exit 1
fi

# Ask for proxy mode (Slot IP or Dedicated IP)
echo "Which type of proxy do you want?"
echo "1. Slot IP"
echo "2. Dedicated IP"
read -p "Enter your choice (1 for Slot, 2 for Dedicated): " ip_restriction

if [[ "$ip_restriction" -ne 1 && "$ip_restriction" -ne 2 ]]; then
    echo "Invalid choice. Please enter 1 or 2."
    exit 1
fi

initialize_or_check_mode

# New or replacement logic
if [ "$proxy_action" -eq 2 ]; then
    # Replacement mode: same creation process but with custom validity
    read -p "How many proxies do you want to replace? " proxy_count
    if [[ ! $proxy_count =~ ^[0-9]+$ ]] || [ "$proxy_count" -le 0 ]; then
        echo "Invalid number of proxies. Exiting."
        exit 1
    fi
    create_proxy "$proxy_count" 1  # Call with replacement flag
else
    # New proxy creation mode (default 31 days)
    read -p "How many proxies do you want to create? " proxy_count
    if [[ ! $proxy_count =~ ^[0-9]+$ ]] || [ "$proxy_count" -le 0 ]; then
        echo "Invalid number of proxies. Exiting."
        exit 1
    fi
    create_proxy "$proxy_count" 0  # Call without replacement flag
fi

# Reload Squid to apply changes
systemctl reload squid > /dev/null 2>&1

# Remove expired proxies after creating new ones
remove_expired_proxies

echo -e "\033[32mOperation completed. Check $LOG_FILE for details.\033[0m"
