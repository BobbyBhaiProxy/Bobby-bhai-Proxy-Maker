#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker with Multiple IP Support
############################################################

LOG_FILE="/root/Proxy.txt"
SAVED_PROXIES_FILE="/root/saved_proxies.txt"

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Function to display the menu
show_menu() {
    echo "1) Create Proxy - Create New Proxy"
    read -p "Select an option by entering 1: " option

    case $option in
        1)
            create_proxy
            ;;
        *)
            echo "Invalid option. Exiting."
            ;;
    esac
}

# Function to create new proxies
create_proxy() {
    # Ensure we don't exceed 3 proxies at once
    proxy_count=$(grep -c "Proxy" "$LOG_FILE")
    if [ "$proxy_count" -ge 3 ]; then
        echo "ERROR: Maximum of 3 proxies allowed at once. Cannot create more."
        exit 1
    fi

    # Ask how many proxies the user wants to create (set to 2 for testing)
    read -p "How many proxies do you want to create? " proxy_count
    if [ "$proxy_count" -le 0 ] || [ "$proxy_count" -gt 3 ]; then
        echo "ERROR: You can only create between 1 and 3 proxies at a time. Exiting."
        exit 1
    fi

    # Set validity to 31 days for all proxies
    validity=31

    # Loop to create the specified number of proxies
    for ((i=1; i<=proxy_count; i++)); do
        # Ask for custom username and password or generate random ones
        read -p "Do you want to use a custom username and password for proxy $i? (yes/no): " custom_choice
        if [[ "$custom_choice" == "yes" ]]; then
            use_custom=1
        else
            use_custom=0
        fi

        # Generate a random username and password if custom is not selected
        if [ "$use_custom" -eq 0 ]; then
            USERNAME=$(generate_random_string 8)
            PASSWORD=$(generate_random_string 12)
            echo "Generated Proxy User with Username: $USERNAME, Password: $PASSWORD"
        else
            read -p "Enter username for Proxy $i: " USERNAME
            read -p "Enter password for Proxy $i: " PASSWORD
        fi

        # Generate a random IP address (as placeholder, replace it with actual IP)
        IP="139.84.209.176"
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
    
    # Check if the status code is 200 (OK)
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e " \033[32mWorking\033[0m"
    else
        echo -e " \033[31mNot working (timeout or error)\033[0m"
    fi
}

# Main function to show menu and create proxies
main() {
    # Show the menu
    show_menu
}

# Run the main function
main
