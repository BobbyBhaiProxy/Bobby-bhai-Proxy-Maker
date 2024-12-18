#!/bin/bash

############################################################
# Bobby Bhai Proxy Maker with Multiple IP Support
############################################################

CONFIG_FILE="/root/proxy_mode.conf"
LOG_FILE="/root/Proxy.txt"

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Detect all server IP addresses
SERVER_IPS=$(hostname -I)
if [ -z "$SERVER_IPS" ]; then
    echo "ERROR: Unable to detect server IPs. Please check your network configuration."
    exit 1
else
    echo "Detected Server IPs: $SERVER_IPS"
fi

# Function to display IP selection menu
select_ip() {
    echo "Select an IP address to use for the proxy:"
    IP_ARRAY=($SERVER_IPS)
    for i in "${!IP_ARRAY[@]}"; do
        echo "$i) ${IP_ARRAY[$i]}"
    done
    read -p "Enter the number corresponding to the IP (or 'all' to use all IPs): " choice
    if [ "$choice" == "all" ]; then
        SELECTED_IPS=("${IP_ARRAY[@]}")
    else
        SELECTED_IPS=("${IP_ARRAY[$choice]}")
    fi
}

# Function to generate a random string
generate_random_string() {
    local length=$1
    tr -dc a-z0-9 </dev/urandom | head -c "$length"
}

# Function to create a proxy with specified IP, username, password, and port
create_proxy_for_ip() {
    local ip=$1
    local port=3128  # Default port for proxy

    echo "Using IP: $ip with port $port."

    # Prompt for custom username and password if requested
    if [ "$use_custom" -eq 1 ]; then
        read -p "Enter username for Proxy User: " custom_username
        read -p "Enter password for Proxy User: " custom_password
        USERNAME="$custom_username"
        PASSWORD="$custom_password"
    else
        USERNAME=$(generate_random_string 8)
        PASSWORD=$(generate_random_string 12)
        echo "Creating Proxy User with Username: $USERNAME, Password: $PASSWORD"
    fi

    # Add user to Squid passwd file
    if [ -f /etc/squid/passwd ]; then
        /usr/bin/htpasswd -b /etc/squid/passwd $USERNAME $PASSWORD
    else
        /usr/bin/htpasswd -b -c /etc/squid/passwd $USERNAME $PASSWORD
    fi

    # Default validity is 31 days
    validity=31

    # Log the proxy with IP, PORT, USERNAME, and PASSWORD
    echo "$ip:$port:$USERNAME:$PASSWORD" >> "$LOG_FILE"

    # Test the proxy
    sleep 3
    test_proxy "$ip" "$USERNAME" "$PASSWORD" "$port"
}

# Function to create proxies across selected IPs
create_proxies() {
    local proxy_count=$1
    for ((i=1; i<=proxy_count; i++)); do
        for ip in "${SELECTED_IPS[@]}"; do
            create_proxy_for_ip "$ip"
        done
    done
}

# Function to test proxy
test_proxy() {
    local PROXY_IP=$1
    local USERNAME=$2
    local PASSWORD=$3
    local PORT=$4

    echo -ne "$PROXY_IP:$PORT:$USERNAME:$PASSWORD | Testing...."
    HTTP_STATUS=$(curl -x http://$USERNAME:$PASSWORD@$PROXY_IP:$PORT -s -o /dev/null --max-time 5 -w "%{http_code}" https://www.irctc.co.in)
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo -e " \033[32mWorking\033[0m"
    else
        echo -e " \033[31mNot working (timeout or error)\033[0m"
    fi
}

# Main function to create new proxies
main() {
    # Ask how many proxies to create
    read -p "How many proxies do you want to create? " proxy_count
    if [[ ! $proxy_count =~ ^[0-9]+$ ]] || [ "$proxy_count" -le 0 ]; then
        echo "Invalid number of proxies. Exiting."
        exit 1
    fi

    # Ask if user wants custom username and password
    read -p "Do you want to use custom username and password? (yes/no): " custom_choice
    if [[ "$custom_choice" == "yes" ]]; then
        use_custom=1
    else
        use_custom=0
    fi

    # Prompt user to select IPs for proxy creation
    select_ip
    create_proxies "$proxy_count"  # Call to create proxies
}

# Menu function for additional actions
show_menu() {
    echo "1) Delete Proxy"
    echo "2) Change Password"
    echo "3) Change Validity"
    read -p "Select an option: " option

    case $option in
        1)
            delete_proxy
            ;;
        2)
            change_password
            ;;
        3)
            change_validity
            ;;
        *)
            echo "Invalid option. Exiting."
            ;;
    esac
}

# Function to delete a proxy
delete_proxy() {
    echo "Available Proxies:"
    cat "$LOG_FILE"
    read -p "Enter the username of the proxy you want to delete: " username
    sed -i "/$username/d" "$LOG_FILE"
    sed -i "/$username/d" /etc/squid/passwd
    systemctl reload squid
    echo "Proxy for user $username deleted."
}

# Function to change password for a proxy
change_password() {
    echo "Available Proxies:"
    cat "$LOG_FILE"
    read -p "Enter the username of the proxy you want to change password for: " username
    read -p "Enter new password: " new_password
    htpasswd -b /etc/squid/passwd $username $new_password
    systemctl reload squid
    echo "Password updated for user $username."
}

# Function to change validity for a proxy
change_validity() {
    echo "Available Proxies:"
    cat "$LOG_FILE"
    read -p "Enter the username of the proxy you want to change validity for: " username
    read -p "Enter new validity period (in days): " new_validity
    # Implement logic to update validity in the log
    echo "Updated validity for $username to $new_validity days."
}

# Ask the user to enter 'show-menu' to display options or create proxies
read -p "Enter 'show-menu' for additional options or 'create' to create new proxies: " action
if [[ "$action" == "show-menu" ]]; then
    show_menu
else
    main
fi
