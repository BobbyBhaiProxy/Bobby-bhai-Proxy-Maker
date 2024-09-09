#!/bin/bash

############################################################
# Automatic Proxy Creation with Correct Testing Format
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

# Count the existing proxies in the log file
EXISTING_PROXIES=$(grep -c "Proxy User" "$LOG_FILE")

if [ "$EXISTING_PROXIES" -ge 50 ]; then
    echo "ERROR: You have already created 50 proxies. No more proxies can be created."
    exit 1
fi

# Prompt for the number of proxies
echo "How many proxies do you want to create? (Limit: 50 total)"
read USER_COUNT

# Validate the user count
if [[ ! $USER_COUNT =~ ^[0-9]+$ ]] || [ $USER_COUNT -le 0 ]]; then
    echo "Invalid number of proxies. Exiting."
    exit 1
fi

# Ensure the total number of proxies does not exceed 50
TOTAL_PROXIES=$((EXISTING_PROXIES + USER_COUNT))
if [ "$TOTAL_PROXIES" -gt 50 ]; then
    echo "ERROR: Total number of proxies exceeds the limit of 50. You can only create $((50 - EXISTING_PROXIES)) more proxies."
    exit 1
fi

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

    # Display testing message
    echo -ne "$PROXY_IP:3128:$USERNAME:$PASSWORD | Testing...."

    # Use curl to test if the proxy can access the target website
    HTTP_STATUS=$(curl -x http://$USERNAME:$PASSWORD@$PROXY_IP:3128 -s -o /dev/null -w "%{http_code}" https://www.irctc.co.in)

    if [ "$HTTP_STATUS" -eq 200 ]; then
        # Show "Working" in green when the proxy is successful
        echo -e " \033[32mWorking\033[0m"
        return 0  # Success
    else
        # Show "Not working" in red when the proxy fails
        echo -e " \033[31mNot working\033[0m"
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

# Function to create proxies
create_proxies() {
    local count=$1
    local proxies=()

    echo "Creating $count proxies..."

    for ((i=1; i<=count; i++)); do
        USERNAME=$(generate_random_string 8)

        # Generate a password and confirm it
        PASSWORD=$(generate_random_string 12)
        CONFIRM_PASSWORD="$PASSWORD"

        # Ensure passwords match before proceeding
        if [ "$PASSWORD" != "$CONFIRM_PASSWORD" ]; then
            echo "ERROR: Passwords do not match. Exiting."
            exit 1
        fi

        echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"

        # Add user to Squid password file
        add_user_to_password_file "$USERNAME" "$PASSWORD"

        # Append proxy to the list
        proxies+=("$SERVER_IP:3128:$USERNAME:$PASSWORD")
    done

    echo "${proxies[@]}"
}

# Create proxies first
proxies=$(create_proxies $USER_COUNT)

# Restart Squid to apply the new proxies
echo "Restarting Squid to apply changes..."
if ! systemctl restart squid; then
    echo "ERROR: Failed to restart Squid service."
    exit 1
fi

# Test each proxy after all are created
working_proxies=()
for proxy in $proxies; do
    IFS=":" read -r PROXY_IP PORT USERNAME PASSWORD <<< "$proxy"

    # Test each proxy once
    test_proxy "$PROXY_IP" "$USERNAME" "$PASSWORD"
    # Log working proxies
    if [ $? -eq 0 ]; then
        working_proxies+=("$proxy")
    fi
done

# After testing all proxies, log the working proxies
if [ ${#working_proxies[@]} -gt 0 ]; then
    echo "Saving working proxies to $LOG_FILE"
    for proxy in "${working_proxies[@]}"; do
        echo "$proxy" >> "$LOG_FILE"
    done
    echo -e "\033[32mProxy testing complete. Working proxies are saved to $LOG_FILE\033[0m"
else
    echo -e "\033[31mNo working proxies found.\033[0m"
fi
