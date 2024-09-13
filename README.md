
# Bobby Bhai Squid Proxy Installer (Updated Version)

[GitHub Repository](https://github.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker.git)

This updated version of Bobby Bhai's Squid Proxy Installer automates the installation, configuration, and management of Squid Proxy with new features like **proxy expiry** and **custom IP and port management**. It supports the following Linux distributions:

- **Ubuntu**: 24.04, 22.04, 20.04, 18.04
- **Debian**: 12, 11, 10, 9, 8
- **CentOS**: 8, Stream 9, 8
- **AlmaLinux**: 9, 8
- **Rocky Linux**: 9, 8
- **Fedora**: 37, 36, 35

---

## New Features
- **Proxy Expiry**: Automatically remove proxies that are older than 30 days and log their removal.
- **Custom IP Management**: Configure proxies using multiple IPs, with options for Slot IP and Dedicated IP modes.
- **Custom Proxy Port**: Select custom ports for proxies during configuration.

---

## Installation Instructions

To install Squid Proxy with the new features, run the following commands:

```bash
wget https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid3-install.sh
sudo bash squid3-install.sh
```

This script will:
- Automatically detect your OS.
- Install Squid Proxy (if not already installed).
- Set up necessary configuration files.
- Prompt you to create proxy users and choose IP restriction modes.
- Automatically configure proxy expiry and clean-up.

---

## Create Proxy Users

After Squid is installed, you can create proxy users with the **create-proxy** script:

```bash
sudo create-proxy
```

This will:
- Ask how many proxies you want to create.
- Prompt for IP restriction mode (Slot IP or Dedicated IP).
- Prompt for the custom proxy port (default is **3128**).
- Generate usernames, passwords, and log proxy details (IP, Port, Username, Password) for future reference.
- Set expiry dates for proxies (automatically removing them after 30 days).

---

## Expiry and Removal of Proxies

This version includes automatic proxy expiry management:
- Proxies older than 30 days will be removed.
- Expired proxies will be logged in `/root/<server_ip>.txt`.
  
To manually check for expired proxies and remove them:

```bash
sudo bash check-expired-proxies.sh
```

This script will:
- Check all active proxies.
- Remove any proxies that have exceeded 30 days.
- Log expired proxies for your records.

---

## IP Restriction Options

1. **Slot IP Mode**: Limits the number of proxies to **4 per IP**.
2. **Dedicated IP Mode**: Allows creating up to **2 proxies per additional IP**.

The **create-proxy** script will prompt you to select one of these modes when creating new proxies.

---

## Configure Multiple IP Addresses

If your server has multiple IP addresses, you can configure Squid to use them for proxy connections. Follow these steps:

```bash
wget https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid-add-ip.sh
sudo bash squid-add-ip.sh
```

This script will:
- Detect available IPs on your server.
- Set up Squid to utilize these IPs for proxies.

---

## Change Squid Proxy Port

To change the default Squid Proxy port (3128):

1. Open the Squid configuration file:
   ```bash
   sudo nano /etc/squid/squid.conf
   ```

2. Locate the line:
   ```bash
   http_port 3128
   ```

3. Change `3128` to your desired port.

4. Reload Squid:
   ```bash
   sudo systemctl reload squid
   ```

---

## Uninstall Squid

To completely remove Squid Proxy, along with its configuration and user files, run:

```bash
sudo ./squid-uninstall.sh
```

This script will:
- Uninstall Squid Proxy.
- Clean up all configuration files and user data related to Squid.

---

## Troubleshooting

For common issues and troubleshooting:

1. **Check Squid logs**:
   ```bash
   sudo tail -f /var/log/squid/access.log
   ```

2. **Reload Squid** to apply new configurations:
   ```bash
   sudo systemctl reload squid
   ```

If you face any issues, visit the [GitHub repository](https://github.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker.git) for further assistance or to open an issue.

---

This update brings advanced features like proxy expiry, custom IP modes, and enhanced management capabilities, making it easier to manage your proxy server effectively.
