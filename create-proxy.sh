#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker with Multiple IP Support
############################################################

CONFIG_FILE="/root/proxy_mode.conf"
LOG_FILE="/root/Proxy.txt"
BACKUP_FILE="/root/proxy_backup.txt"

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Function to display the menu
show_menu() {
    echo "1) create-proxy - Create New Proxy"
    echo "2) change-password - Change Proxy Password"
    echo "3) backup-data - Backup Proxy Data"
    echo "4) restore-data - Restore Proxy Data"
    read -p "Select an option: " option

    case $option in
        1)
            create_proxy
            ;;
        2)
            change_password
            ;;
        3)
            backup_data
            ;;
        4)
            restore_data
            ;;
        *)
            echo "Invalid option. Exiting."
            ;;
    esac
}

# Function to create a new proxy
create_proxy() {
    # Check if the maximum of 5 IPs is already created
    proxy_count=$(grep -c "Proxy" "$LOG_FILE")
    if [ "$proxy_count" -ge 5 ]; then
        echo "ERROR: Maximum of 5 proxies already created. Cannot create more."
        exit 1
    fi

    # Ask if user wants custom username and password
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

    # Add user to Squid passwd file
    if [ -f /etc/squid/passwd ]; then
        /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
    else
        /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
    fi

    # Log the proxy with USERNAME and PASSWORD
    echo "Proxy created with Username: $USERNAME, Password: $PASSWORD" >> "$LOG_FILE"

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

# Function to change password for an existing proxy
change_password() {
    echo "Available Proxies:"
    cat "$LOG_FILE"
    read -p "Enter the username of the proxy you want to change password for: " username
    read -p "Enter new password: " new_password
    htpasswd -b /etc/squid/passwd $username $new_password
    systemctl reload squid
    echo "Password updated for user $username."
}

# Function to back up proxy data
backup_data() {
    echo "Backing up proxy data..."
    cp "$LOG_FILE" "$BACKUP_FILE"
    echo "Backup saved to $BACKUP_FILE"
}

# Function to restore proxy data from backup
restore_data() {
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$LOG_FILE"
        echo "Restored proxy data from backup."
    else
        echo "Backup file not found. No data to restore."
    fi
}

# Main function to create proxy or show menu
main() {
    read -p "Enter 'show-menu' to view available options or 'create-proxy' to create a proxy: " action
    case $action in
        "show-menu")
            show_menu
            ;;
        "create-proxy")
            create_proxy
            ;;
        *)
            echo "Invalid command. Please enter 'show-menu' or 'create-proxy'."
            ;;
    esac
}

# Run the main function
main
