#!/bin/bash

############################################################
# Create bobby bhai Proxy Maker 
# Author: Bobby Bhai
############################################################

# Check if the script is running as root
if [ `whoami` != root ]; then
    echo "ERROR: You need to run the script as root or add sudo before the command."
    exit 1
fi

# Log file for proxy details (append all proxies here)
LOG_FILE="/root/ProxyList.txt"

# Check if the log file exists, if not create it
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Prompt for the number of proxies
echo "How many proxies do you want to add?"
read USER_COUNT

# Validate the user count
if [[ ! $USER_COUNT =~ ^[0-9]+$ ]] || [ $USER_COUNT -le 0 ]; then
    echo "Invalid number of users. Exiting."
    exit 1
fi

# IP Series Selection for X-Forwarded-For header
echo "Enter the first two segments of your desired IP (e.g., 172.232, 103.15):"
read -p "IP series: " IP_PREFIX

echo "Selected IP Prefix: $IP_PREFIX"

# Add a comment in the log file to indicate the start of this session
echo -e "\n# Proxy Session on $(date)" >> "$LOG_FILE"

# Start creating additional proxy users
for ((i=1;i<=USER_COUNT;i++)); do
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

    # Append user and IP details to the Squid config
    echo -e "acl user$i proxy_auth $USERNAME\nheader_access X-Forwarded-For allow user$i\nrequest_header_add X-Forwarded-For \"$SPOOFED_IP\" user$i" >> /etc/squid/squid.conf

    # Log generated proxy details in the log file (append to the ProxyList.txt)
    echo "$SPOOFED_IP:3128:$USERNAME:$PASSWORD" >> "$LOG_FILE"
    echo "Proxy details logged for $USERNAME"
done

# Restart Squid service to apply changes
echo "Restarting Squid to apply changes..."
systemctl restart squid
if [ $? -eq 0 ]; then
    echo "Squid restarted successfully."
else
    echo "ERROR: Failed to restart Squid service."
    exit 1
fi

echo -e "\033[32mProxy users have been created and saved to $LOG_FILE\033[0m"
