#!/bin/bash

############################################################
# Simple Proxy Maker with Dynamic IP and Proxy Testing
############################################################

LOG_FILE="/root/Proxy.txt"

# Ensure log file exists
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Ask how many proxies the user wants to create (limit to 3)
read -p "How many proxies do you want to create? (1-3): " proxy_count

if [ "$proxy_count" -le 0 ] || [ "$proxy_count" -gt 3 ]; then
    echo "ERROR: You can only create between 1 and 3 proxies at a time. Exiting."
    exit 1
fi

# Get the server's internal IP address (no user input)
IP=$(hostname -I | awk '{print $1}')
PORT="3128"  # Fixed port

# Function to test the proxy
test_proxy() {
    local IP=$1
    local PORT=$2
    local USERNAME=$3
    local PASSWORD=$4

    # Test the proxy by calling the IRCTC website and checking the status
    HTTP_STATUS=$(curl -x http://$USERNAME:$PASSWORD@$IP:$PORT -s -o /dev/null --max-time 5 -w "%{http_code}" https://www.irctc.co.in/)
    
    # Display the result
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e "Proxy $IP:$PORT:$USERNAME:$PASSWORD \033[32mWorking\033[0m"
    else
        echo -e "Proxy $IP:$PORT:$USERNAME:$PASSWORD \033[31mNot working (timeout or error)\033[0m"
    fi
}

# Loop to create the specified number of proxies
for ((i=1; i<=proxy_count; i++)); do
    read -p "Enter username for Proxy $i: " USERNAME
    read -p "Enter password for Proxy $i: " PASSWORD

    # Log the proxy in the specified format: IP:PORT:USERNAME:PASSWORD
    echo "$IP:$PORT:$USERNAME:$PASSWORD" >> "$LOG_FILE"

    echo "Proxy $i created and logged: $IP:$PORT:$USERNAME:$PASSWORD"

    # Test the proxy
    test_proxy "$IP" "$PORT" "$USERNAME" "$PASSWORD"
done

echo "Proxies have been logged in $LOG_FILE."
