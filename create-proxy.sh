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
    echo "2) backup-proxies - Backup All Proxies"
    echo "3) restore-proxies - Restore Proxies"
    echo "4) replacement - Replace Existing Proxy"
    read -p "Select an option by entering 1, 2, 3, or 4: " option

    case $option in
        1)
            create_proxy
            ;;
        2)
            backup_proxies
            ;;
        3)
            restore_proxies
            ;;
        4)
            replacement
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

    # Ask for custom username and password or generate random ones
    read -p "Do you want to use custom username and password? (yes/no): " custom_choice
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
        read -p "Enter username for Proxy User: " USERNAME
        read -p "Enter password for Proxy User: " PASSWORD
    fi

    # Ask for the number of days the proxy should be valid
    read -p "How many days do you want the proxy to remain valid? " validity
    if [[ ! $validity =~ ^[0-9]+$ ]] || [ "$validity" -le 0 ]; then
        echo "Invalid number of days. Exiting."
        exit 1
    fi

    # Add user to Squid passwd file
    if [ -f /etc/squid/passwd ]; then
        /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
    else
        /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
    fi

    # Log the proxy with USERNAME, PASSWORD, VALIDITY
    echo "Proxy created with Username: $USERNAME, Password: $PASSWORD, Validity: $validity days" >> "$LOG_FILE"

    # Save the proxy data in persistent file for future re-creation
    echo "$USERNAME:$PASSWORD:$validity" >> "$SAVED_PROXIES_FILE"

    # Test the proxy by calling a website to confirm it's working
    sleep 3
    test_proxy "$USERNAME" "$PASSWORD"
}

# Function to generate a random string for usernames and passwords
generate_random_string() {
    local length=$1
    tr -dc a-z0-9 </dev/urandom | head -c "$length"
}

# Function to test if proxy is working
test_proxy() {
    local USERNAME=$1
    local PASSWORD=$2
    local PORT=3128

    echo -ne "Testing proxy: $USERNAME:$PASSWORD | Testing...."
    HTTP_STATUS=$(curl -x http://$USERNAME:$PASSWORD@127.0.0.1:$PORT -s -o /dev/null --max-time 5 -w "%{http_code}" https://www.irctc.co.in)
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e " \033[32mWorking\033[0m"
    else
        echo -e " \033[31mNot working (timeout or error)\033[0m"
    fi
}

# Function to back up all proxy data
backup_proxies() {
    echo "Backing up all proxies..."
    cp "$SAVED_PROXIES_FILE" "$BACKUP_FILE"
    echo "Backup saved to $BACKUP_FILE"
}

# Function to restore proxy data from backup
restore_proxies() {
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$SAVED_PROXIES_FILE"
        echo "Restored proxy data from backup."
    else
        echo "Backup file not found. No data to restore."
    fi
}

# Function to replace an existing proxy
replacement() {
    echo "Available Proxies:"
    cat "$SAVED_PROXIES_FILE"
    read -p "Enter the username of the proxy you want to replace: " old_username

    # Ask for new credentials
    read -p "Enter new username for Proxy: " new_username
    read -p "Enter new password for Proxy: " new_password
    read -p "How many days do you want the proxy to remain valid? " validity

    # Replace the old proxy in Squid passwd file
    htpasswd -b /etc/squid/passwd $new_username $new_password
    sed -i "/$old_username/d" "$SAVED_PROXIES_FILE"
    
    # Log the new proxy with USERNAME, PASSWORD, VALIDITY
    echo "$new_username:$new_password:$validity" >> "$SAVED_PROXIES_FILE"

    # Update proxy log
    echo "Proxy replaced with Username: $new_username, Password: $new_password, Validity: $validity days" >> "$LOG_FILE"

    systemctl reload squid
    echo "Proxy for user $old_username replaced with $new_username."
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
