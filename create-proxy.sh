#!/bin/bash

############################################################

############################################################

# Check if the script is running as root
if [ `whoami` != root ]; then
	echo "ERROR: You need to run the script as root or add sudo before command."
	exit 1
fi

# Check if htpasswd is installed
if [ ! -f /usr/bin/htpasswd ]; then
    echo "ERROR: htpasswd not found. Please install apache2-utils or httpd-tools."
    exit 1
fi

# Log file location
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

# Function to generate a random string of specified length
generate_random_string() {
    local length=$1
    tr -dc A-Za-z0-9 </dev/urandom | head -c $length
}

# Ask the user to select mode: Manual (M) or Automatic (A)
read -p "Select Mode (M for Manual, A for Automatic): " mode_choice

if [[ "$mode_choice" == "M" || "$mode_choice" == "m" ]]; then
    # Manual input mode
    read -p "Enter Proxy username: " USERNAME
    read -p "Enter Proxy password: " PASSWORD

    # Check if password file exists and add user
    if [ -f /etc/squid/passwd ]; then
        /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
    else
        /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
    fi

    # Log the created proxy in the format IP:PORT:USERNAME:PASSWORD
    echo "$SERVER_IP:3128:$USERNAME:$PASSWORD" >> "$LOG_FILE"

    echo "Proxy created and saved to $LOG_FILE:"
    echo "$SERVER_IP:3128:$USERNAME:$PASSWORD"

elif [[ "$mode_choice" == "A" || "$mode_choice" == "a" ]]; then
    # Automatic mode
    read -p "How many proxies do you want to create? " proxy_count

    if [[ ! $proxy_count =~ ^[0-9]+$ ]] || [ "$proxy_count" -le 0 ]; then
        echo "Invalid number of proxies. Exiting."
        exit 1
    fi

    for ((i=1; i<=proxy_count; i++)); do
        # Generate a random username and password
        USERNAME=$(generate_random_string 8)
        PASSWORD=$(generate_random_string 12)

        echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"

        # Check if password file exists and add user
        if [ -f /etc/squid/passwd ]; then
            /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
        else
            /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
        fi

        # Log the created proxy in the format IP:PORT:USERNAME:PASSWORD
        echo "$SERVER_IP:3128:$USERNAME:$PASSWORD" >> "$LOG_FILE"
    done

    # Reload Squid to apply the new proxies
    echo "Reloading Squid to apply new configurations..."
    systemctl reload squid > /dev/null 2>&1

    echo -e "\033[32m$proxy_count proxies created and saved to $LOG_FILE\033[0m"
else
    echo "Invalid mode selected. Exiting."
    exit 1
fi
