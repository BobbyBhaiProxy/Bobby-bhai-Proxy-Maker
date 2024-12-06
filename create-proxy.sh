#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker with Multiple IP Support
############################################################

CONFIG_FILE="/root/proxy_mode.conf"
LOG_FILE="/root/Proxy.txt"
BACKUP_FILE="/root/proxy_backup.txt"
SAVED_PROXIES_FILE="/root/saved_proxies.txt"

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Function to display the menu
show_menu() {
    echo "1) create-proxy - Create New Proxy"
    echo "2) replace-validity - Replace Validity of Existing Proxy"
    read -p "Select an option by entering 1 or 2: " option

    case $option in
        1)
            create_proxy
            ;;
        2)
            replace_validity
            ;;
        *)
            echo "Invalid option. Exiting."
            ;;
    esac
}

# Function to create a new proxy
create_proxy() {
    # Ensure we don't exceed 5 proxies
    proxy_count=$(grep -c "Proxy" "$LOG_FILE")
    if [ "$proxy_count" -ge 5 ]; then
        echo "ERROR: Maximum of 5 proxies already created. Cannot create more."
        exit 1
    fi

    # Ask for how many proxies the user wants to create
    read -p "How many proxies do you want to create? " proxy_count
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

        # Ask for custom validity (between 1 and 31 days)
        read -p "Enter validity (1-31 days) for Proxy $i: " validity
        if [[ ! $validity =~ ^[0-9]+$ ]] || [ "$validity" -lt 1 ] || [ "$validity" -gt 31 ]; then
            echo "Invalid validity period. Setting validity to 31 days."
            validity=31
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

    # After creating the proxies, show the menu again
    show_menu
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

# Function to replace validity of an existing proxy
replace_validity() {
    # Display all saved proxies
    echo "Existing Proxies:"
    cat "$SAVED_PROXIES_FILE"

    # Ask for the username of the proxy to modify
    read -p "Enter the username of the proxy whose validity you want to change: " username_to_modify

    # Check if the username exists in the saved proxies file
    if ! grep -q "$username_to_modify" "$SAVED_PROXIES_FILE"; then
        echo "ERROR: Proxy with username $username_to_modify does not exist."
        return
    fi

    # Ask for new validity period (between 1 and 31 days)
    read -p "Enter new validity (1-31 days) for Proxy $username_to_modify: " new_validity

    # Validate the input to ensure the validity is within 1 to 31 days
    if [[ ! $new_validity =~ ^[0-9]+$ ]] || [ "$new_validity" -lt 1 ] || [ "$new_validity" -gt 31 ]; then
        echo "ERROR: Invalid validity period. It must be between 1 and 31 days. Exiting."
        return
    fi

    # Create a new proxy with the modified validity
    # Fetch the username and password from the existing proxy data
    existing_proxy_data=$(grep "$username_to_modify" "$SAVED_PROXIES_FILE")
    if [[ ! -z "$existing_proxy_data" ]]; then
        USERNAME=$(echo $existing_proxy_data | cut -d: -f1)
        PASSWORD=$(echo $existing_proxy_data | cut -d: -f2)

        # Generate a random IP address (as placeholder, replace it with actual IP)
        IP="139.84.209.176"
        PORT="3128"

        # Log the new proxy with the updated validity
        echo "$IP:$PORT:$USERNAME:$PASSWORD" >> "$LOG_FILE"
        echo "$USERNAME:$PASSWORD:$new_validity" >> "$SAVED_PROXIES_FILE"

        # Test the proxy by calling a website to confirm it's working
        sleep 3
        test_proxy "$IP" "$PORT" "$USERNAME" "$PASSWORD"

        # Confirm new proxy creation
        echo "Created a new proxy with updated validity: $new_validity days."
    fi

    # Show the menu again
    show_menu
}

# Function to delete all proxy files before installation
cleanup() {
    echo "Cleaning up old proxy files before installation..."
    rm -f "$LOG_FILE" "$SAVED_PROXIES_FILE" "$BACKUP_FILE"
    echo "Old proxy files deleted successfully."
}

# Function to delete the script itself after execution
cleanup_script() {
    echo "Deleting script after execution..."
    rm -f "$0"
}

# Main function to create proxy or show menu
main() {
    # Clean up old files before starting
    cleanup

    # Ask for the user's action
    clear
    echo "Choose an option to proceed:"
    echo "1) Show Menu"
    echo "2) Create Proxy"
    read -p "Enter 1 to Show Menu or 2 to Create Proxy: " action
    if [ "$action" -eq 1 ]; then
        show_menu
    elif [ "$action" -eq 2 ]; then
        create_proxy
    else
        echo "Invalid option. Exiting."
        exit 1
    fi

    # Clean up after the script is done
    cleanup_script
}

# Run the main function
main
