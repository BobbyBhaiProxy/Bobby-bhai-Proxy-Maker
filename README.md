
# Bobby Bhai Squid Proxy Installer (Updated Version)

[GitHub Repository](https://github.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker.git)

This updated version of Bobby Bhai's Squid Proxy Installer automates the installation and configuration of Squid 3 proxy on the following Linux distributions:

- **Ubuntu**: 24.04, 22.04, 20.04, 18.04
- **Debian**: 12, 11, 10, 9, 8
- **CentOS**: 8, Stream 9, 8
- **AlmaLinux**: 9, 8

---

## Installation Instructions

To install Squid Proxy, run the following commands:

```bash
wget https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid3-install.sh
sudo bash squid3-install.sh
```

This script will:
- Automatically detect your OS.
- Install Squid Proxy (if not already installed).
- Set up necessary configuration files.
- Prompt you to create proxy users after installation.

---

## Create Proxy Users

Once Squid is installed, you can create proxy users using the **create-proxy** script:

```bash
sudo create-proxy
```

The script will:
- Prompt you to enter the number of proxies you want to create.
- Ask for the first two segments of the IP address.
- Automatically generate usernames, passwords, and complete IP addresses.
- Log the proxy details (IP, Port, Username, Password) to a file for reference.

### Manually Create Users (Optional)

If you prefer, you can manually create proxy users with the following command:

```bash
sudo /usr/bin/htpasswd -b -c /etc/squid/passwd USERNAME_HERE PASSWORD_HERE
```

To update the password for an existing user, use:

```bash
sudo /usr/bin/htpasswd /etc/squid/passwd USERNAME_HERE
```

After creating or updating users, reload Squid Proxy to apply the changes:

```bash
sudo systemctl reload squid
```

---

## Multiple IP Address Configuration

> **Note**: Only needed if you have more than one IP address on your server.

After adding additional IPs to your server, you can configure Squid to use them by running the following script:

```bash
wget https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid-conf-ip.sh
sudo bash squid-conf-ip.sh
```

This will configure Squid to handle multiple IP addresses for use in the proxy server.

---

## Change Squid Proxy Port

The default Squid Proxy port is **3128**. If you wish to change the port, modify the Squid configuration file (`/etc/squid/squid.conf`):

1. Open the file in a text editor:
   ```bash
   sudo nano /etc/squid/squid.conf
   ```

2. Find the line:
   ```bash
   http_port 3128
   ```

3. Change `3128` to your desired port number and save the file.

4. Reload Squid to apply the new port:
   ```bash
   sudo systemctl reload squid
   ```

---

## Uninstall Squid

To completely uninstall Squid Proxy and remove all associated configuration files, run:

```bash
sudo ./squid-uninstall.sh
```

This script will:
- Remove Squid Proxy and its related packages.
- Clean up configuration files and directories.

---

## Troubleshooting

If you encounter issues or need further assistance, check the logs in `/var/log/squid/` or reload Squid Proxy for configuration issues:

```bash
sudo systemctl reload squid
```

For support or more details, please visit the [GitHub repository](https://github.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker.git).
