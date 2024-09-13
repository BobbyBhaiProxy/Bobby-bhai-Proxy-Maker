#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker with Custom Port, IP Restriction, and Expiry Feature
############################################################

# Check if the script is running as root
if [ `whoami` != root ]; then
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
    tr -dc a-z0-9 </dev/urandom | head -c $length
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
    ip -4 addr show | grep -c inet | grep -v "$SERVER_IP"
}

# Function to check for expired proxies and remove them
remove_expired_proxies() {
    # Loop through each line in the log file to check for expired proxies
    while IFS= read -r line; do
        creation_date=$(echo "$line" | awk '{print $5}')  # Assuming date is stored at position 5 in log format
        username=$(echo "$line" | awk -F ':' '{print $3}')  # Extract username from log entry

        # Calculate the difference in days from the creation date
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

# Ask the user to select the proxy mode
read -p "Select Mode (M for Manual, A for Automatic): " mode_choice
read -p "Enter the custom port for the proxy (1024-65535): " custom_port

if [[ ! "$custom_port" =~ ^[0-9]+$ ]] || [ "$custom_port" -lt 1024 ] || [ "$custom_port" -gt 65535 ]]; then
    echo "Invalid port number. Exiting."
    exit 1
fi

# Ask the user to select the type of IP restriction: Slot or Dedicated
echo "Select IP Restriction:"
echo "1. Slot IP (max 4 proxies)"
echo "2. Dedicated IP (up to 2 proxies per additional IP)"
read -p "Enter your choice (1 for Slot, 2 for Dedicated): " ip_restriction

if [ "$ip_restriction" -eq 1 ]; then
    # Slot IP: Limit proxies to 4
    existing_proxies=$(count_existing_proxies)
    if [ "$existing_proxies" -ge 4 ]; then
        echo "ERROR: You have reached the limit of 4 proxies on this server."
        exit 1
    fi
elif [ "$ip_restriction" -eq 2 ]; then
    # Dedicated IP: Check if additional IPs are available
    additional_ips=$(check_additional_ips)
    if [ "$additional_ips" -eq 0 ]; then
        echo "No additional IPs found. You can only create 1 proxy."
        max_proxies=1
    else
        echo "Additional IPs found. You can create up to 2 proxies."
        max_proxies=2
    fi
else
    echo "Invalid IP restriction choice. Exiting."
    exit 1
fi

if [[ "$mode_choice" == "M" || "$mode_choice" == "m" ]]; then
    read -p "Enter Proxy username: " USERNAME
    read -p "Enter Proxy password: " PASSWORD
    if [ -f /etc/squid/passwd ]; then
        /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
    else
        /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
    fi
    echo "$SERVER_IP:$custom_port:$USERNAME:$PASSWORD $(date '+%d-%m-%y')" >> "$LOG_FILE"  # Log creation date
    echo "Proxy created and saved to $LOG_FILE:"
    echo "$SERVER_IP:$custom_port:$USERNAME:$PASSWORD"

elif [[ "$mode_choice" == "A" || "$mode_choice" == "a" ]]; then
    read -p "How many proxies do you want to create? " proxy_count

    if [[ ! $proxy_count =~ ^[0-9]+$ ]] || [ "$proxy_count" -le 0 ] || [ "$proxy_count" -gt "$max_proxies" ]]; then
        echo "Invalid number of proxies. You can only create up to $max_proxies proxies."
        exit 1
    fi

    # Log the timestamp in Indian date-time format (DD-MM-YY HH:MM AM/PM) and add a single line gap
    echo -e "\nThis set of proxies is created at $(date '+%d-%m-%y %I:%M %p' --date='TZ=\"Asia/Kolkata\"')" >> "$LOG_FILE"
    for ((i=1; i<=proxy_count; i++)); do
        USERNAME=$(generate_random_string 8)
        PASSWORD=$(generate_random_string 12)
        echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"
        if [ -f /etc/squid/passwd ]; then
            /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
        else
            /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
        fi
        echo "$SERVER_IP:$custom_port:$USERNAME:$PASSWORD $(date '+%d-%m-%y')" >> "$LOG_FILE"  # Log creation date
        sleep 3
        test_proxy "$SERVER_IP" "$USERNAME" "$PASSWORD" "$custom_port"
    done
    systemctl reload squid > /dev/null 2>&1
    echo -e "\033[32m$proxy_count proxies created and saved to $LOG_FILE\033[0m"
else
    echo "Invalid mode selected. Exiting."
    exit 1
fi

# Remove expired proxies after creating new ones
remove_expired_proxies
