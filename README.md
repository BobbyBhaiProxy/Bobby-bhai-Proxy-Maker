
# Bobby Bhai Squid Proxy Installer (Updated Version)

https://github.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker.git

This updated version of Bobby Bhai's Squid Proxy Installer auto-installs Squid 3 proxy on the following Linux OS distributions:

* Ubuntu 24.04, 22.04, 20.04, 18.04 
* Debian 12, 11, 10, 9, 8
* CentOS 8
* CentOS Stream 9, 8
* AlmaLinux 9, 8

## Install Squid

To install, run the script:

```
wget https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid3-install.sh
sudo bash squid3-install.sh
```

This script will:
- Detect your operating system.
- Install Squid if it’s not already installed.
- Prompt you to create proxies after installation.

## Create Proxy Users

Once Squid is installed, you can create users by running:

```
sudo ./add_proxy.sh
```

OR manually by running:

```
sudo /usr/bin/htpasswd -b -c /etc/squid/passwd USERNAME_HERE PASSWORD_HERE
```

To update the password for an existing user, run:

```
sudo /usr/bin/htpasswd /etc/squid/passwd USERNAME_HERE
```

Replace `USERNAME_HERE` and `PASSWORD_HERE` with your desired username and password.

Once users are created or updated, reload Squid Proxy:

```
sudo systemctl reload squid
```

## Configure Multiple IP Addresses

NOTE: This is only needed if you have more than one IP on your server.

After adding additional IPs to your server, configure Squid to use them by running the following command:

```
wget https://raw.githubusercontent.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker/main/squid-conf-ip.sh
sudo bash squid-conf-ip.sh
```

This will set up multiple IP addresses for use in the Squid proxy.

## Change Squid Proxy Port

The default Squid Proxy port is `3128`. To change the Squid port, modify the Squid configuration file (`squid.conf`) as needed.

## Uninstall Squid

To completely uninstall Squid from your system, run:

```
sudo ./squid-uninstall.sh
```

This script will remove Squid and all associated configuration files.

## Support

For assistance or more details, please visit the GitHub repository:

https://github.com/BobbyBhaiProxy/Bobby-bhai-Proxy-Maker.git
