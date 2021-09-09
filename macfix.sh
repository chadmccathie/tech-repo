#!/usr/bin/env bash

#This will fix the annoying problem of cloning a vmware workstation centos vm and finding out you have no eth0 interface!

#Grab the MAC address from dmesg
mac=`dmesg | grep eth0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`

#Remove the kernel.s networking interface rules file(Don't worry it will be regenerated)
rm -f /etc/udev/rules.d/70-persistent-net.rules

# Remove the current MAC address
sed -i '3s/.*//' /etc/sysconfig/network-scripts/ifcfg-eth0

# Place the new mac address into the file
echo 'HWADDR="'$mac'"' >>  /etc/sysconfig/network-scripts/ifcfg-eth0

#Reboot for changes to take effect
reboot

# 1

# 4
