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
elif grep -q "jessie" /etc/os-release; then
    echo "debian8"
elif grep -q "stretch" /etc/os-release; then
    echo "debian9"
elif grep -q "buster" /etc/os-release; then
    echo "debian10"
elif grep -q "bullseye" /etc/os-release; then
    echo "debian11"
elif grep -q "bookworm" /etc/os-release; then
    echo "debian12"

# Check for CentOS and AlmaLinux versions
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

# If no match, return error
else
    echo "ERROR: OS not supported."
fi
