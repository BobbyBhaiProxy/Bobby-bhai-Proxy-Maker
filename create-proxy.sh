#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker
# Author: Your Name
# Github: https://github.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker
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

# Prompt for the number of proxies
echo "How many proxies do you want to create? (Limit: 50 total)"
read USER_COUNT

# Validate the user count
if [[ ! $USER_COUNT =~ ^[0-9]+$ ]] || [ "$USER_COUNT" -le 0 ]; then
    echo "Invalid number of proxies. Exiting."
    exit 1
fi

# Ensure find-os script is available
/usr/bin/wget -q --no-check-certificate -O /usr/bin/sok-find-os https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/sok-find-os.sh
chmod 755 /usr/bin/sok-find-os

# Ensure create-proxy script is available
/usr/bin/wget -q --no-check-certificate -O /usr/bin/create-proxy https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/create-proxy.sh
chmod 755 /usr/bin/create-proxy

# Add a comment in the log file to indicate the start of this session
echo -e "\n# Proxy Session on $(date)" >> "$LOG_FILE"

# Function to generate a random string of specified length
generate_random_string() {
    local length=$1
    tr -dc A-Za-z0-9 </dev/urandom | head -c $length
}

# Function to add user to password file
add_user_to_password_file() {
    local USERNAME=$1
    local PASSWORD=$2

    if [ ! -f /etc/squid/passwd ]; then
        echo "Creating new /etc/squid/passwd file"
        htpasswd -cb /etc/squid/passwd "$USERNAME" "$PASSWORD"
    else
        echo "Adding user to /etc/squid/passwd"
        htpasswd -b /etc/squid/passwd "$USERNAME" "$PASSWORD"
    fi
}

# Function to create proxies and save them to the log file
create_proxies() {
    local count=$1
    local proxies=()

    echo "Creating $count proxies..."

    for ((i=1; i<=count; i++)); do
        USERNAME=$(generate_random_string 8)

        # Generate a password
        PASSWORD=$(generate_random_string 12)

        echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"

        # Add user to Squid password file
        add_user_to_password_file "$USERNAME" "$PASSWORD"

        # Format proxy as IP:PORT:USERNAME:PASSWORD
        proxy="$SERVER_IP:3128:$USERNAME:$PASSWORD"

        # Append proxy to the log file
        echo "$proxy" >> "$LOG_FILE"

        # Store proxy in the array (if needed for later processing)
        proxies+=("$proxy")
    done

    echo "${proxies[@]}"
}

# Create and log the proxies
create_proxies $USER_COUNT

echo -e "\033[32mProxy creation complete. All proxies are saved to $LOG_FILE\033[0m"
