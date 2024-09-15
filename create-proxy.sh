#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker with Custom Port and IP Restriction
############################################################

# Configuration file to store the chosen mode
CONFIG_FILE="/root/proxy_mode.conf"

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

# Log file for proxy details, named after the server IP
LOG_FILE="/root/${SERVER_IP}.txt"
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Function to generate a random string of lowercase alphabet and numbers of specified length
generate_random_string() {
    local length=$1
    tr -dc a-z0-9 </dev/urandom | head -c "$length"
}

# Function to test if the proxy can access the website, with a 5-second timeout
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

# Function to check the number of existing proxies in the log
count_existing_proxies() {
    grep -c "$SERVER_IP" "$LOG_FILE"
}

# Check if there are additional IPs on the server
check_additional_ips() {
    ip -4 addr show | grep inet | grep -v "$SERVER_IP" | grep -v '127.0.0.1' | wc -l
}

# Function to check for expired proxies and remove them
remove_expired_proxies() {
    while IFS= read -r line; do
        creation_date=$(echo "$line" | awk '{print $5}')  # Assuming date is stored at position 5 in log format
        username=$(echo "$line" | awk -F ':' '{print $3}')  # Extract username from log entry
        days_diff=$(( ( $(date +%s) - $(date -d "$creation_date" +%s) ) / 86400 ))

        # If the difference exceeds 30 days, remove the proxy and log the event
        if [ "$days_diff" -gt 30 ]; then
            echo "Proxy $username has expired. Removing it from the server."
            /usr/bin/htpasswd -D /etc/squid/passwd "$username"  # Remove user from Squid passwd file
            sed -i "/$username/d" "$LOG_FILE"  # Remove entry from log file
            echo "$(date '+%d-%m-%y %I:%M %p') - Proxy $username has been removed (Expired after 30 days)." >> "$LOG_FILE"
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

# Ask the user for the type of proxy (Slot IP or Dedicated IP)
if [ -f "$CONFIG_FILE" ]; then
    echo "Proxy mode has already been set. You cannot change it."
    stored_mode=$(cat "$CONFIG_FILE")
    if [ "$stored_mode" -eq 1 ]; then
        echo "Current mode: Slot IP"
    elif [ "$stored_mode" -eq 2 ]; then
        echo "Current mode: Dedicated IP"
    else
        echo "ERROR: Invalid mode in configuration file."
        exit 1
    fi
    exit 0
fi

echo "Which type of proxy do you want?"
echo "1. Slot IP"
echo "2. Dedicated IP"
read -p "Enter your choice (1 for Slot, 2 for Dedicated): " ip_restriction

if [[ "$ip_restriction" -ne 1 && "$ip_restriction" -ne 2 ]]; then
    echo "Invalid choice. Please enter 1 or 2."
    exit 1
fi

initialize_or_check_mode

# Ask if the user wants a custom port or not
read -p "Would you like to use a custom port? (y/n): " use_custom_port

if [[ "$use_custom_port" == "y" || "$use_custom_port" == "Y" ]]; then
    read -p "Enter the custom port for the proxy (1024-65535): " custom_port
    if [[ ! "$custom_port" =~ ^[0-9]+$ ]] || [ "$custom_port" -lt 1024 ] || [ "$custom_port" -gt 65535 ]; then
        echo "Invalid port number. Exiting."
        exit 1
    fi
else
    custom_port=3128  # Default port
    echo "Using default port 3128."
fi

# Ask how many proxies to create
read -p "How many proxies do you want to create? " proxy_count

if [[ ! $proxy_count =~ ^[0-9]+$ ]] || [ "$proxy_count" -le 0 ]; then
    echo "Invalid number of proxies. Exiting."
    exit 1
fi

# Limit checks based on Slot IP or Dedicated IP
existing_proxies=$(count_existing_proxies)

if [ "$ip_restriction" -eq 1 ] && [ "$proxy_count" -gt 4 ]; then
    echo "ERROR: Slot IP mode allows a maximum of 4 proxies. You requested $proxy_count proxies."
    exit 1
elif [ "$ip_restriction" -eq 2 ] && [ "$proxy_count" -gt 2 ]; then
    additional_ips=$(check_additional_ips)
    if [ "$additional_ips" -eq 0 ]; then
        echo "ERROR: No additional IPs found. Only 1 proxy can be created in Dedicated IP mode."
        exit 1
    elif [ "$proxy_count" -gt 2 ]; then
        echo "ERROR: Dedicated IP mode allows a maximum of 2 proxies per IP. You requested $proxy_count proxies."
        exit 1
    fi
fi

# Log the timestamp in Indian date-time format (DD-MM-YY HH:MM AM/PM) and add a single line gap
echo -e "\nThis set of proxies is created at $(TZ='Asia/Kolkata' date '+%d-%m-%y %I:%M %p')" >> "$LOG_FILE"

# Create proxies
for ((i=1; i<=proxy_count; i++)); do
    USERNAME=$(generate_random_string 8)
    PASSWORD=$(generate_random_string 12)
    echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"
    if [ -f /etc/squid/passwd ]; then
        /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
    else
        /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
    fi
    # Corrected the echo line to properly write to the log file
    echo "$SERVER_IP:$custom_port:$USERNAME:$PASSWORD" >> "$LOG_FILE"
    sleep 3
    test_proxy "$SERVER_IP" "$USERNAME" "$PASSWORD" "$custom_port"
done

# Reload Squid to apply the changes
systemctl reload squid > /dev/null 2>&1

# Remove expired proxies after creating new ones
remove_expired_proxies

echo -e "\033[32m$proxy_count proxies created and saved to $LOG_FILE\033[0m"
