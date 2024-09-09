#!/bin/bash

############################################################
# Create Proxy Users with Auto-Testing and Server IP Detection
############################################################

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
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
echo "How many working proxies do you want to create?"
read USER_COUNT

# Validate the user count
if [[ ! $USER_COUNT =~ ^[0-9]+$ ]] || [ $USER_COUNT -le 0 ]; then
    echo "Invalid number of users. Exiting."
    exit 1
fi

# Calculate the maximum number of attempts for testing proxies
MAX_ATTEMPTS=$((USER_COUNT * 2))

# Add a comment in the log file to indicate the start of this session
echo -e "\n# Proxy Session on $(date)" >> "$LOG_FILE"

# Function to generate a random string of specified length
generate_random_string() {
    local length=$1
    tr -dc A-Za-z0-9 </dev/urandom | head -c $length
}

# Function to test if the proxy can access the website
test_proxy() {
    local PROXY_IP=$1
    local USERNAME=$2
    local PASSWORD=$3

    echo "Testing proxy $PROXY_IP:3128..."

    # Use curl to test if the proxy can access the target website
    HTTP_STATUS=$(curl -x http://$USERNAME:$PASSWORD@$PROXY_IP:3128 -s -o /dev/null -w "%{http_code}" https://www.irctc.co.in)

    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo "Proxy is working!"
        return 0  # Success
    else
        echo "Proxy is not working."
        return 1  # Failure
    fi
}

# Function to add user to password file
add_user_to_password_file() {
    local USERNAME=$1
    local PASSWORD=$2

    if [ ! -f /etc/squid/passwd ]; then
        echo "Creating new /etc/squid/passwd file"
        htpasswd -cb /etc/squid/passwd $USERNAME $PASSWORD
    else
        echo "Adding user to /etc/squid/passwd"
        htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
    fi
}

# Function to create and test proxies
create_and_test_proxies() {
    local count=$1
    local max_attempts=$2
    local proxies=()

    echo "Creating and testing $count proxies..."

    for ((i=1; i<=count; i++)); do
        USERNAME=$(generate_random_string 8)
        PASSWORD=$(generate_random_string 12)

        echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"

        # Add user to Squid password file
        add_user_to_password_file "$USERNAME" "$PASSWORD"

        # Restart Squid to apply the new proxy
        echo "Restarting Squid to apply changes..."
        if ! systemctl restart squid; then
            echo "ERROR: Failed to restart Squid service."
            exit 1
        fi

        # Test if the proxy works with the target URL
        PROXY_IP="$SERVER_IP"  # Use the detected server IP
        if test_proxy "$PROXY_IP" "$USERNAME" "$PASSWORD"; then
            # If the proxy works, save it to the list and continue
            proxies+=("$PROXY_IP:3128:$USERNAME:$PASSWORD")
        else
            echo "Proxy failed."
        fi
    done

    # Return the array of working proxies
    echo "${proxies[@]}"
}

# Create and test proxies
working_proxies=$(create_and_test_proxies $USER_COUNT $MAX_ATTEMPTS)

# Check if we have enough working proxies
if [ $(echo "$working_proxies" | wc -w) -ne $USER_COUNT ]; then
    echo "ERROR: Not all proxies are working. Please check the script and try again."
    exit 1
else
    echo "All proxies are working and saved to $LOG_FILE"
    echo -e "${working_proxies}" >> "$LOG_FILE"
fi

echo -e "\033[32mWorking proxy users have been created and saved to $LOG_FILE\033[0m"
