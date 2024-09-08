#!/bin/bash

############################################################
# Create Proxy Users with Auto-Testing
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

# Prompt for the number of proxies
echo "How many working proxies do you want to create?"
read USER_COUNT

# Validate the user count
if [[ ! $USER_COUNT =~ ^[0-9]+$ ]] || [ $USER_COUNT -le 0 ]; then
    echo "Invalid number of users. Exiting."
    exit 1
fi

# Prompt for IP series for spoofing the X-Forwarded-For header
echo "Enter the first two segments of your desired IP (e.g., 172.232, 103.15):"
read -p "IP series: " IP_PREFIX

echo "Selected IP Prefix: $IP_PREFIX"

# Add a comment in the log file to indicate the start of this session
echo -e "\n# Proxy Session on $(date)" >> "$LOG_FILE"

# Function to generate a random string of specified length
generate_random_string() {
    local length=$1
    tr -dc A-Za-z0-9 </dev/urandom | head -c $length
}

# Function to test if the proxy can access the website
function test_proxy {
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
        echo "Proxy is not working. Trying again..."
        return 1  # Failure
    fi
}

# Start creating additional proxy users
for ((i=1;i<=USER_COUNT;i++)); do
    while true; do
        USERNAME=$(generate_random_string 8)
        PASSWORD=$(generate_random_string 12)

        echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"

        # Generate IP address
        OCTET=$(shuf -i 1-254 -n 1)
        SPOOFED_IP="${IP_PREFIX}.$OCTET"

        echo "Generated Spoofed IP: $SPOOFED_IP for User $USERNAME"

        # Add user to Squid password file
        if [ ! -f /etc/squid/passwd ]; then
            echo "Creating new /etc/squid/passwd file"
            htpasswd -cb /etc/squid/passwd $USERNAME $PASSWORD
        else
            echo "Adding user to /etc/squid/passwd"
            htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
        fi

        # Append user and IP details to the Squid config for X-Forwarded-For spoofing
        echo -e "acl user$i proxy_auth $USERNAME" >> /etc/squid/squid.conf
        echo "request_header_add X-Forwarded-For \"$SPOOFED_IP\" user$i" >> /etc/squid/squid.conf

        # Restart Squid to apply the new proxy
        echo "Restarting Squid to apply changes..."
        systemctl restart squid
        if [ $? -eq 0 ]; then
            echo "Squid restarted successfully."
        else
            echo "ERROR: Failed to restart Squid service."
            exit 1
        fi

        # Test if the proxy works with the target URL
        if test_proxy "$SPOOFED_IP" "$USERNAME" "$PASSWORD"; then
            # If the proxy works, log it and break out of the loop
            echo "$SPOOFED_IP:3128:$USERNAME:$PASSWORD" >> "$LOG_FILE"
            echo "Proxy details logged for $USERNAME"
            break
        else
            # If the proxy doesn't work, retry by generating a new one
            echo "Retrying with a new IP..."
        fi
    done
done

echo -e "\033[32mWorking proxy users have been created and saved to $LOG_FILE\033[0m"
