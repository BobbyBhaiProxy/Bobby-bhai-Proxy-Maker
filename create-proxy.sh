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

# Calculate the maximum number of attempts for testing proxies
MAX_ATTEMPTS=$((USER_COUNT * 5))

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
        echo "Proxy is not working."
        return 1  # Failure
    fi
}

# Function to create and test proxies
create_and_test_proxies() {
    local count=$1
    local ip_prefix=$2
    local max_attempts=$3
    local proxies=()

    echo "Creating and testing $count proxies..."

    for ((i=1; i<=count; i++)); do
        attempt=1
        while [ $attempt -le $max_attempts ]; do
            USERNAME=$(generate_random_string 8)
            PASSWORD=$(generate_random_string 12)

            echo "Creating Proxy User $i with Username: $USERNAME, Password: $PASSWORD"

            # Generate IP address
            OCTET=$(shuf -i 1-254 -n 1)
            SPOOFED_IP="${ip_prefix}.$OCTET"

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
            if ! systemctl restart squid; then
                echo "ERROR: Failed to restart Squid service."
                exit 1
            fi

            # Test if the proxy works with the target URL
            if test_proxy "$SPOOFED_IP" "$USERNAME" "$PASSWORD"; then
                # If the proxy works, save it to the list and break the loop
                proxies+=("$SPOOFED_IP:3128:$USERNAME:$PASSWORD")
                break
            else
                # If the proxy doesn't work, retry or fail if the maximum attempts are reached
                echo "Proxy failed. Attempt $attempt of $max_attempts."
                attempt=$((attempt + 1))
                if [ $attempt -gt $max_attempts ]; then
                    echo "Max attempts reached for proxy creation. Skipping."
                    break
                fi
            fi
        done
    done

    # Return the array of working proxies
    echo "${proxies[@]}"
}

# Create and test proxies initially
working_proxies=$(create_and_test_proxies $USER_COUNT $IP_PREFIX $MAX_ATTEMPTS)

# Check if we have enough working proxies
if [ $(echo "$working_proxies" | wc -w) -ne $USER_COUNT ]; then
    echo "Not all proxies worked with spoofing. Retrying without IP spoofing..."

    # Clear previous configuration
    echo "Clearing previous proxy configuration..."
    sed -i '/acl user/d' /etc/squid/squid.conf
    sed -i '/request_header_add X-Forwarded-For/d' /etc/squid/squid.conf

    # Restart Squid to apply the clean configuration
    if ! systemctl restart squid; then
        echo "ERROR: Failed to restart Squid service."
        exit 1
    fi

    # Create and test proxies without spoofing
    working_proxies=$(create_and_test_proxies $USER_COUNT "" $MAX_ATTEMPTS)

    # Check if all proxies are working
    if [ $(echo "$working_proxies" | wc -w) -eq $USER_COUNT ]; then
        echo "All proxies are working and saved to $LOG_FILE"
        echo -e "${working_proxies}" >> "$LOG_FILE"
    else
        echo "ERROR: Not all proxies are working. Please check the script and try again."
        exit 1
    fi
else
    echo "All proxies are working and saved to $LOG_FILE"
    echo -e "${working_proxies}" >> "$LOG_FILE"
fi

echo -e "\033[32mWorking proxy users have been created and saved to $LOG_FILE\033[0m"
