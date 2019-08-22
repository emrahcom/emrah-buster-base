#!/bin/bash

# -----------------------------------------------------------------------------
# REMINDER.SH
# -----------------------------------------------------------------------------
set -e
source $INSTALLER/000_source

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_REMINDER" = true ] && exit

echo
echo "------------------------- REMINDER -------------------------"

if [ "0" = "$SWAP" ]
then
    echo
    echo "Add swap file to the host, if there is no swap (mostly on cloud)"
    echo ">>> dd if=/dev/zero of=/swapfile bs=1M count=2048"
    echo ">>> chmod 600 /swapfile"
    echo ">>> mkswap /swapfile"
    echo ">>> swapon /swapfile"
    echo ">>> echo '/swapfile none  swap  sw  0  0' >>/etc/fstab"
fi

echo
echo "Install the 'open-vm-tools' package to the host (VM only)"
echo ">>> apt-get install open-vm-tools"
