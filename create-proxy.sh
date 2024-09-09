#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker with Spoofed IPs and Logging Updates
############################################################

# Check if the script is running as root
if [ `whoami` != root ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Log file for proxy details
LOG_FILE="/root/ProxyList.txt"

# Check if the log file exists, if not create it
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Detect the server's public IP address
SERVER_IP=$(curl -s ifconfig.me)

if [ -z "$SERVER_IP" ]; then
    echo "ERROR: Unable to detect the server IP. Please check your internet connection."
    exit 1
else
    echo "Detected Server IP: $SERVER_IP"
fi

# Function to generate a random string of lowercase alphabet and numbers of specified length
generate_random_string() {
    local length=$1
    tr -dc a-z0-9 </dev/urandom | head -c $length
}

# Function to generate a spoofed IP based on user input
generate_spoofed_ip() {
    local ip_prefix=$1
    local third_octet=$(shuf -i 0-255 -n 1)
    local fourth_octet=$(shuf -i 1-255 -n 1)
    echo "$ip_prefix$third_octet.$fourth_octet"
}

# Function to test if the proxy can access the website with the spoofed IP
test_proxy() {
    local PROXY_IP=$1
    local USERNAME=$2
    local PASSWORD=$3
    local SPOOFED_IP=$4

    # Display testing message
    echo -ne "$PROXY_IP:3128:$USERNAME:$PASSWORD | Testing...."

    # Use curl to test if the proxy can access the target website with the spoofed IP
    HTTP_STATUS=$(curl -x http://$USERNAME:$PASSWORD@$PROXY_IP:3128 -H "X-Forwarded-For: $SPOOFED_IP" -s -o /dev/null -w "%{http_code}" https://www.irctc.co.in)

    if [ "$HTTP_STATUS" -eq 200 ]; then
        # Show "Working" in green when the proxy is successful
        echo -e " \033[32mWorking\033[0m (Spoofed IP: $SPOOFED_IP)"
        return 0  # Success
    else
        # Show "Not working" in red when the proxy fails
        echo -e " \033[31mNot working\033[0m (Spoofed IP: $SPOOFED_IP)"
        return 1  # Failure
    fi
}

# Get user input for the first two segments of the IP (e.g., 172.211.)
read -p "Enter the first two segments of the proxy IP (e.g., 172.211.): " ip_prefix

# Ask the user to select mode: Manual (M) or Automatic (A)
read -p "Select Mode (M for Manual, A for Automatic): " mode_choice

if [[ "$mode_choice" == "M" || "$mode_choice" == "m" ]]; then
    # Manual input mode
    read -p "Enter Proxy username: " USERNAME
    read -p "Enter Proxy password: " PASSWORD

    # Generate a spoofed IP based on the input prefix
    SPOOFED_IP=$(generate_spoofed_ip $ip_prefix)

    # Check if password file exists and add user
    if [ -f /etc/squid/passwd ]; then
        /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
    else
        /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
    fi

    # Log the created proxy in the format IP:PORT:USERNAME:PASSWORD with a timestamp comment
    echo -e "\n# This Proxy is created at $(date)" >> "$LOG_FILE"
    echo "$SERVER_IP:3128:$USERNAME:$PASSWORD" >> "$LOG_FILE"

    # Test the proxy with spoofed IP
    test_proxy "$SERVER_IP" "$USERNAME" "$PASSWORD" "$SPOOFED_IP"

    echo "Proxy created and saved to $LOG_FILE:"
    echo "$SERVER_IP:3128:$USERNAME:$PASSWORD"

elif [[ "$mode_choice" == "A" || "$mode_choice" == "a" ]]; then
    # Automatic mode
    read -p "How many proxies do you want to create? " proxy_count

    if [[ ! $proxy_count =~ ^[0-9]+$ ]] || [ "$proxy_count" -le 0 ]; then
        echo "Invalid number of proxies. Exiting."
        exit 1
    fi

    # Log a comment indicating when these proxies were created
    echo -e "\n# These Proxies are created at $(date)" >> "$LOG_FILE"

    for ((i=1; i<=proxy_count; i++)); do
        # Generate a random username and password in lowercase
        USERNAME=$(generate_random_string 8)
        PASSWORD=$(generate_random_string 12)

        echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"

        # Generate a spoofed IP based on the input prefix
        SPOOFED_IP=$(generate_spoofed_ip $ip_prefix)

        # Check if password file exists and add user
        if [ -f /etc/squid/passwd ]; then
            /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
        else
            /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
        fi

        # Log the created proxy in the format IP:PORT:USERNAME:PASSWORD
        echo "$SERVER_IP:3128:$USERNAME:$PASSWORD" >> "$LOG_FILE"

        # Introduce a delay of 3 seconds between each proxy creation
        sleep 3

        # Test the created proxy with the spoofed IP
        test_proxy "$SERVER_IP" "$USERNAME" "$PASSWORD" "$SPOOFED_IP"
    done

    # Reload Squid to apply the new proxies
    echo "Reloading Squid to apply new configurations..."
    systemctl reload squid > /dev/null 2>&1

    echo -e "\033[32m$proxy_count proxies created and saved to $LOG_FILE\033[0m"
else
    echo "Invalid mode selected. Exiting."
    exit 1
fi
