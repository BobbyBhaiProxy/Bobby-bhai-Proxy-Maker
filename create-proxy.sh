#!/bin/bash

############################################################
# Simple Proxy Maker with Dynamic IP
############################################################

LOG_FILE="/root/Proxy.txt"
SAVED_PROXIES_FILE="/root/saved_proxies.txt"

# Ensure log file exists
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Function to create new proxies
create_proxy() {
    # Ensure we don't exceed 3 proxies
    proxy_count=$(grep -c "Proxy" "$LOG_FILE")
    if [ "$proxy_count" -ge 3 ]; then
        echo "Maximum of 3 proxies allowed at once. Cannot create more."
        exit 1
    fi

    # Ask how many proxies the user wants to create (limit to 3)
    read -p "How many proxies do you want to create? " proxy_count
    if [ "$proxy_count" -le 0 ] || [ "$proxy_count" -gt 3 ]; then
        echo "You can only create between 1 and 3 proxies at a time. Exiting."
        exit 1
    fi

    # Set validity to 31 days for all proxies
    validity=31

    # Get the server's internal IP address (no user input)
    IP=$(hostname -I | awk '{print $1}')
    echo "Using internal server IP: $IP"

    # Ask for custom username and password once (applies to all proxies)
    read -p "Do you want to use a custom username and password for all proxies? (yes/no): " custom_choice
    if [[ "$custom_choice" == "yes" ]]; then
        use_custom=1
        read -p "Enter username for all proxies: " USERNAME
        read -p "Enter password for all proxies: " PASSWORD
    else
        use_custom=0
    fi

    # Loop to create the specified number of proxies
    for ((i=1; i<=proxy_count; i++)); do
        # Generate a random username and password if custom is not selected
        if [ "$use_custom" -eq 0 ]; then
            USERNAME=$(generate_random_string 8)
            PASSWORD=$(generate_random_string 12)
            echo "Generated Proxy User with Username: $USERNAME, Password: $PASSWORD"
        fi

        # Generate a random port (or use a fixed one)
        PORT="3128"

        # Log the proxy in the specified format: IP:PORT:USERNAME:PASSWORD
        echo "$IP:$PORT:$USERNAME:$PASSWORD" >> "$LOG_FILE"

        # Save the proxy data in persistent file for future re-creation
        echo "$USERNAME:$PASSWORD:$validity" >> "$SAVED_PROXIES_FILE"

        # Test the proxy by calling a website to confirm it's working
        sleep 3
        test_proxy "$IP" "$PORT" "$USERNAME" "$PASSWORD"
    done
}

# Function to generate a random string for usernames and passwords
generate_random_string() {
    local length=$1
    tr -dc a-z0-9 </dev/urandom | head -c "$length"
}

# Function to test if proxy is working
test_proxy() {
    local IP=$1
    local PORT=$2
    local USERNAME=$3
    local PASSWORD=$4

    # Display the full proxy information during the test
    echo -ne "Testing proxy: $IP:$PORT:$USERNAME:$PASSWORD | Testing...."
    
    # Test the proxy by calling a website and checking the status
    HTTP_STATUS=$(curl -x http://$USERNAME:$PASSWORD@$IP:$PORT -s -o /dev/null --max-time 5 -w "%{http_code}" https://www.irctc.co.in)
    
    # Debugging output
    echo "HTTP Status: $HTTP_STATUS"

    # Check if the status code is 200 (OK)
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e " \033[32mWorking\033[0m"
    else
        echo -e " \033[31mNot working (timeout or error)\033[0m"
    fi
}

# Main function to create proxies
main() {
    # Run the proxy creation
    create_proxy
}

# Run the main function
main
