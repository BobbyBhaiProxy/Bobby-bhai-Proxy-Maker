#!/bin/bash

############################################################
# OS Detection Script for Bobby Bhai Proxy Maker
############################################################

# Check for Ubuntu versions
if grep -q "Ubuntu 24.04" /etc/os-release; then
    echo "ubuntu2404"
elif grep -q "Ubuntu 22.04" /etc/os-release; then
    echo "ubuntu2204"
elif grep -q "Ubuntu 20.04" /etc/os-release; then
    echo "ubuntu2004"
elif grep -q "Ubuntu 18.04" /etc/os-release; then
    echo "ubuntu1804"
elif grep -q "Ubuntu 16.04" /etc/os-release; then
    echo "ubuntu1604"
elif grep -q "Ubuntu 14.04" /etc/os-release; then
    echo "ubuntu1404"

# Check for Debian versions
elif grep -q "bookworm" /etc/os-release; then
    echo "debian12"
elif grep -q "bullseye" /etc/os-release; then
    echo "debian11"
elif grep -q "buster" /etc/os-release; then
    echo "debian10"
elif grep -q "stretch" /etc/os-release; then
    echo "debian9"
elif grep -q "jessie" /etc/os-release; then
    echo "debian8"

# Check for CentOS, AlmaLinux, Rocky Linux versions
elif grep -q "CentOS Linux 7" /etc/os-release; then
    echo "centos7"
elif grep -q "CentOS Linux 8" /etc/os-release; then
    echo "centos8"
elif grep -q "AlmaLinux 8" /etc/os-release; then
    echo "almalinux8"
elif grep -q "AlmaLinux 9" /etc/os-release; then
    echo "almalinux9"
elif grep -q "CentOS Stream 8" /etc/os-release; then
    echo "centos8s"
elif grep -q "CentOS Stream 9" /etc/os-release; then
    echo "centos9"
elif grep -q "Rocky Linux 8" /etc/os-release; then
    echo "rockylinux8"
elif grep -q "Rocky Linux 9" /etc/os-release; then
    echo "rockylinux9"

# Check for Fedora versions
elif grep -q "Fedora release" /etc/os-release; then
    echo "fedora"

# Check for Alpine Linux
elif grep -q "Alpine Linux" /etc/os-release; then
    echo "alpine"

# Check for Arch Linux
elif grep -q "Arch Linux" /etc/os-release; then
    echo "archlinux"

# Check for openSUSE
elif grep -q "openSUSE Leap 15" /etc/os-release; then
    echo "opensuse15"

# Check for FreeBSD
elif grep -q "FreeBSD" /etc/os-release; then
    echo "freebsd"

# Check for OpenBSD
elif grep -q "OpenBSD" /etc/os-release; then
    echo "openbsd"

# If no match, return error
else
    echo "ERROR: OS not supported."
fi
